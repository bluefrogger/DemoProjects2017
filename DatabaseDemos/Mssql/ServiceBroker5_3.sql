--Lesson 1: Creating the Target Database
--Create a Service Broker endpoint
USE master;
GO
IF EXISTS (SELECT * FROM master.sys.endpoints
           WHERE name = N'InstTargetEndpoint')
     DROP ENDPOINT InstTargetEndpoint;
GO
CREATE ENDPOINT InstTargetEndpoint
STATE = STARTED
AS TCP ( LISTENER_PORT = 4022 )
FOR SERVICE_BROKER (AUTHENTICATION = WINDOWS );
GO

--Create the target database, master key, and user
USE master;
GO
IF EXISTS (SELECT * FROM sys.databases
           WHERE name = N'InstTargetDB')
     DROP DATABASE InstTargetDB;
GO
CREATE DATABASE InstTargetDB;
GO
USE InstTargetDB;
GO
CREATE MASTER KEY
       ENCRYPTION BY PASSWORD = N'<EnterStrongPassword1Here>';
GO
CREATE USER TargetUser WITHOUT LOGIN;
GO

--Create the target certificate
CREATE CERTIFICATE InstTargetCertificate 
     AUTHORIZATION TargetUser
     WITH SUBJECT = 'Target Certificate',
          EXPIRY_DATE = N'12/31/2010';

BACKUP CERTIFICATE InstTargetCertificate
  TO FILE = 
N'C:\storedcerts\$ampleSSBCerts\InstTargetCertificate.cer';
GO

--Create the message types
CREATE MESSAGE TYPE [//BothDB/2InstSample/RequestMessage]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//BothDB/2InstSample/ReplyMessage]
       VALIDATION = WELL_FORMED_XML;
GO

--Create the contract
CREATE CONTRACT [//BothDB/2InstSample/SimpleContract]
      ([//BothDB/2InstSample/RequestMessage]
         SENT BY INITIATOR,
       [//BothDB/2InstSample/ReplyMessage]
         SENT BY TARGET
      );
GO

--Create the target queue and service
CREATE QUEUE InstTargetQueue;

CREATE SERVICE [//TgtDB/2InstSample/TargetService]
       AUTHORIZATION TargetUser
       ON QUEUE InstTargetQueue
       ([//BothDB/2InstSample/SimpleContract]);
GO

--Lesson 2: Creating the Initiator Database
--Create a Service Broker endpoint
USE master;
GO
IF EXISTS (SELECT * FROM sys.endpoints
           WHERE name = N'InstInitiatorEndpoint')
     DROP ENDPOINT InstInitiatorEndpoint;
GO
CREATE ENDPOINT InstInitiatorEndpoint
STATE = STARTED
AS TCP ( LISTENER_PORT = 4022 )
FOR SERVICE_BROKER (AUTHENTICATION = WINDOWS );
GO

--Create the initiator database, master key, and user
USE master;
GO
IF EXISTS (SELECT * FROM sys.databases
           WHERE name = N'InstInitiatorDB')
     DROP DATABASE InstInitiatorDB;
GO
CREATE DATABASE InstInitiatorDB;
GO
USE InstInitiatorDB;
GO

CREATE MASTER KEY
       ENCRYPTION BY PASSWORD = N'<EnterStrongPassword2Here>';
GO
CREATE USER InitiatorUser WITHOUT LOGIN;
GO

--Create the initiator certificate
CREATE CERTIFICATE InstInitiatorCertificate
     AUTHORIZATION InitiatorUser
     WITH SUBJECT = N'Initiator Certificate',
          EXPIRY_DATE = N'12/31/2010';

BACKUP CERTIFICATE InstInitiatorCertificate
  TO FILE = 
N'C:\storedcerts\$ampleSSBCerts\InstInitiatorCertificate.cer';
GO

--Create the message types
CREATE MESSAGE TYPE [//BothDB/2InstSample/RequestMessage]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//BothDB/2InstSample/ReplyMessage]
       VALIDATION = WELL_FORMED_XML;
GO

--Create the contract
CREATE CONTRACT [//BothDB/2InstSample/SimpleContract]
      ([//BothDB/2InstSample/RequestMessage]
         SENT BY INITIATOR,
       [//BothDB/2InstSample/ReplyMessage]
         SENT BY TARGET
      );
GO

--Create the initiator queue and service
CREATE QUEUE InstInitiatorQueue;

CREATE SERVICE [//InstDB/2InstSample/InitiatorService]
       AUTHORIZATION InitiatorUser
       ON QUEUE InstInitiatorQueue;
GO

--Create references to target objects
CREATE USER TargetUser WITHOUT LOGIN;

CREATE CERTIFICATE InstTargetCertificate 
   AUTHORIZATION TargetUser
   FROM FILE = 
N'C:\storedcerts\$ampleSSBCerts\InstTargetCertificate.cer'
GO

--Create routes
DECLARE @Cmd NVARCHAR(4000);

SET @Cmd = N'USE InstInitiatorDB;
CREATE ROUTE InstTargetRoute
WITH SERVICE_NAME =
       N''//TgtDB/2InstSample/TargetService'',
     ADDRESS = N''TCP://MyTargetComputer:4022'';';

EXEC (@Cmd);

SET @Cmd = N'USE msdb
CREATE ROUTE InstInitiatorRoute
WITH SERVICE_NAME =
       N''//InstDB/2InstSample/InitiatorService'',
     ADDRESS = N''LOCAL''';

EXEC (@Cmd);
GO
CREATE REMOTE SERVICE BINDING TargetBinding
      TO SERVICE
         N'//TgtDB/2InstSample/TargetService'
      WITH USER = TargetUser;

GO

--Lesson 3: Completing the Target Conversation Objects
--Create references to initiator objects
USE InstTargetDB
GO
CREATE USER InitiatorUser WITHOUT LOGIN;

CREATE CERTIFICATE InstInitiatorCertificate
   AUTHORIZATION InitiatorUser
   FROM FILE = 
N'C:\storedcerts\$ampleSSBCerts\InstInitiatorCertificate.cer';
GO

--Create routes
DECLARE @Cmd NVARCHAR(4000);

SET @Cmd = N'USE InstTargetDB;
CREATE ROUTE InstInitiatorRoute
WITH SERVICE_NAME =
       N''//InstDB/2InstSample/InitiatorService'',
     ADDRESS = N''TCP://MyInitiatorComputer:4022'';';

EXEC (@Cmd);

SET @Cmd = N'USE msdb
CREATE ROUTE InstTargetRoute
WITH SERVICE_NAME =
        N''//TgtDB/2InstSample/TargetService'',
     ADDRESS = N''LOCAL''';

EXEC (@Cmd);
GO
GRANT SEND
      ON SERVICE::[//TgtDB/2InstSample/TargetService]
      TO InitiatorUser;
GO
CREATE REMOTE SERVICE BINDING InitiatorBinding
      TO SERVICE N'//InstDB/2InstSample/InitiatorService'
      WITH USER = InitiatorUser;
GO

--Lesson 4: Beginning the Conversation
--Switch to the InitiatorDB database
USE InstInitiatorDB;
GO

--Start a conversation and send a request message
DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
DECLARE @RequestMsg NVARCHAR(100);

BEGIN TRANSACTION;

BEGIN DIALOG @InitDlgHandle
     FROM SERVICE [//InstDB/2InstSample/InitiatorService]
     TO SERVICE N'//TgtDB/2InstSample/TargetService'
     ON CONTRACT [//BothDB/2InstSample/SimpleContract]
     WITH
         ENCRYPTION = ON;

SELECT @RequestMsg = N'<RequestMsg>Message for Target service.</RequestMsg>';

SEND ON CONVERSATION @InitDlgHandle
     MESSAGE TYPE [//BothDB/2InstSample/RequestMessage]
     (@RequestMsg);

SELECT @RequestMsg AS SentRequestMsg;

COMMIT TRANSACTION;
GO

--Lesson 5: Receiving a Request and Sending a Reply
--Switch to the TargetDB database
USE InstTargetDB;
GO

--Receive the request and send a reply
DECLARE @RecvReqDlgHandle UNIQUEIDENTIFIER;
DECLARE @RecvReqMsg NVARCHAR(100);
DECLARE @RecvReqMsgName sysname;

BEGIN TRANSACTION;

WAITFOR
( RECEIVE TOP(1)
    @RecvReqDlgHandle = conversation_handle,
    @RecvReqMsg = message_body,
    @RecvReqMsgName = message_type_name
  FROM InstTargetQueue
), TIMEOUT 1000;

SELECT @RecvReqMsg AS ReceivedRequestMsg;

IF @RecvReqMsgName = N'//BothDB/2InstSample/RequestMessage'
BEGIN
     DECLARE @ReplyMsg NVARCHAR(100);
     SELECT @ReplyMsg =
        N'<ReplyMsg>Message for Initiator service.</ReplyMsg>';

     SEND ON CONVERSATION @RecvReqDlgHandle
          MESSAGE TYPE [//BothDB/2InstSample/ReplyMessage]
          (@ReplyMsg);

     END CONVERSATION @RecvReqDlgHandle;
END

SELECT @ReplyMsg AS SentReplyMsg;

COMMIT TRANSACTION;
GO

--Lesson 6: Receiving the Reply and Ending the Conversation
--Switch to the InitiatorDB database
USE InstInitiatorDB;
GO

--Receive the reply and end the conversation
DECLARE @RecvReplyMsg NVARCHAR(100);
DECLARE @RecvReplyDlgHandle UNIQUEIDENTIFIER;

BEGIN TRANSACTION;

WAITFOR
( RECEIVE TOP(1)
    @RecvReplyDlgHandle = conversation_handle,
    @RecvReplyMsg = message_body
  FROM InstInitiatorQueue
), TIMEOUT 1000;

END CONVERSATION @RecvReplyDlgHandle;

-- Display recieved request.
SELECT @RecvReplyMsg AS ReceivedReplyMsg;

COMMIT TRANSACTION;
GO
