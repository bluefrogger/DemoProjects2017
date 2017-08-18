/*
https://technet.microsoft.com/en-us/library/bb839489(v=sql.105).aspx
*/
--Lesson 1: Creating the Conversation Objects
--Enable Service Broker and switch to the AdventureWorks2008R2 database
USE master;
GO
ALTER DATABASE AdventureWorks2008R2
      SET ENABLE_BROKER;
GO
USE AdventureWorks2008R2;
GO

--Create the message types
CREATE MESSAGE TYPE
       [//AWDB/1DBSample/RequestMessage]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE
       [//AWDB/1DBSample/ReplyMessage]
       VALIDATION = WELL_FORMED_XML;
GO

--Create the contract
CREATE CONTRACT [//AWDB/1DBSample/SampleContract]
      ([//AWDB/1DBSample/RequestMessage]
       SENT BY INITIATOR,
       [//AWDB/1DBSample/ReplyMessage]
       SENT BY TARGET
      );
GO

--Create the target queue and service
CREATE QUEUE TargetQueue1DB;

CREATE SERVICE
       [//AWDB/1DBSample/TargetService]
       ON QUEUE TargetQueue1DB
       ([//AWDB/1DBSample/SampleContract]);
GO

--Create the initiator queue and service
CREATE QUEUE InitiatorQueue1DB;

CREATE SERVICE
       [//AWDB/1DBSample/InitiatorService]
       ON QUEUE InitiatorQueue1DB;
GO

--Lesson 2: Beginning a Conversation and Transmitting Messages
--Switch to the AdventureWorks2008R2 database
USE AdventureWorks2008R2;
GO

--Begin a conversation and send a request message
DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
DECLARE @RequestMsg NVARCHAR(100);

BEGIN TRANSACTION;

BEGIN DIALOG @InitDlgHandle
     FROM SERVICE
      [//AWDB/1DBSample/InitiatorService]
     TO SERVICE
      N'//AWDB/1DBSample/TargetService'
     ON CONTRACT
      [//AWDB/1DBSample/SampleContract]
     WITH
         ENCRYPTION = OFF;

SELECT @RequestMsg =
       N'<RequestMsg>Message for Target service.</RequestMsg>';

SEND ON CONVERSATION @InitDlgHandle
     MESSAGE TYPE 
     [//AWDB/1DBSample/RequestMessage]
     (@RequestMsg);

SELECT @RequestMsg AS SentRequestMsg;

COMMIT TRANSACTION;
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
  FROM TargetQueue1DB
), TIMEOUT 1000;

SELECT @RecvReqMsg AS ReceivedRequestMsg;

IF @RecvReqMsgName =
   N'//AWDB/1DBSample/RequestMessage'
BEGIN
     DECLARE @ReplyMsg NVARCHAR(100);
     SELECT @ReplyMsg =
     N'<ReplyMsg>Message for Initiator service.</ReplyMsg>';
 
     SEND ON CONVERSATION @RecvReqDlgHandle
          MESSAGE TYPE 
          [//AWDB/1DBSample/ReplyMessage]
          (@ReplyMsg);

     END CONVERSATION @RecvReqDlgHandle;
END

SELECT @ReplyMsg AS SentReplyMsg;

COMMIT TRANSACTION;
GO

--Receive the reply and end the conversation
DECLARE @RecvReplyMsg NVARCHAR(100);
DECLARE @RecvReplyDlgHandle UNIQUEIDENTIFIER;

BEGIN TRANSACTION;

WAITFOR
( RECEIVE TOP(1)
    @RecvReplyDlgHandle = conversation_handle,
    @RecvReplyMsg = message_body
  FROM InitiatorQueue1DB
), TIMEOUT 1000;

END CONVERSATION @RecvReplyDlgHandle;

SELECT @RecvReplyMsg AS ReceivedReplyMsg;

COMMIT TRANSACTION;
GO

--Lesson 3: Dropping the Conversation Objects
--Switch to the AdventureWorks2008R2 database

USE AdventureWorks2008R2;
GO

--Drop the conversation objects
IF EXISTS (SELECT * FROM sys.services
           WHERE name =
           N'//AWDB/1DBSample/TargetService')
     DROP SERVICE
     [//AWDB/1DBSample/TargetService];

IF EXISTS (SELECT * FROM sys.service_queues
           WHERE name = N'TargetQueue1DB')
     DROP QUEUE TargetQueue1DB;

-- Drop the intitator queue and service if they already exist.
IF EXISTS (SELECT * FROM sys.services
           WHERE name =
           N'//AWDB/1DBSample/InitiatorService')
     DROP SERVICE
     [//AWDB/1DBSample/InitiatorService];

IF EXISTS (SELECT * FROM sys.service_queues
           WHERE name = N'InitiatorQueue1DB')
     DROP QUEUE InitiatorQueue1DB;

IF EXISTS (SELECT * FROM sys.service_contracts
           WHERE name =
           N'//AWDB/1DBSample/SampleContract')
     DROP CONTRACT
     [//AWDB/1DBSample/SampleContract];

IF EXISTS (SELECT * FROM sys.service_message_types
           WHERE name =
           N'//AWDB/1DBSample/RequestMessage')
     DROP MESSAGE TYPE
     [//AWDB/1DBSample/RequestMessage];

IF EXISTS (SELECT * FROM sys.service_message_types
           WHERE name =
           N'//AWDB/1DBSample/ReplyMessage')
     DROP MESSAGE TYPE
     [//AWDB/1DBSample/ReplyMessage];
GO


