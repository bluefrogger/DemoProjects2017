--Lesson 1: Creating the Databases
--Create the databases and set the trustworthy option
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases
           WHERE name = N'TargetDB')
     DROP DATABASE TargetDB;
GO
CREATE DATABASE TargetDB;
GO

IF EXISTS (SELECT * FROM sys.databases
           WHERE name = N'InitiatorDB')
     DROP DATABASE InitiatorDB;
GO
CREATE DATABASE InitiatorDB;
GO
ALTER DATABASE InitiatorDB SET TRUSTWORTHY ON;
GO

--Lesson 2: Creating the Target Conversation Objects
--Switch to the TargetDB database
USE TargetDB;
GO

--Create the message types
CREATE MESSAGE TYPE [//BothDB/2DBSample/RequestMessage]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//BothDB/2DBSample/ReplyMessage]
       VALIDATION = WELL_FORMED_XML;
GO

--Create the contract
CREATE CONTRACT [//BothDB/2DBSample/SimpleContract]
      ([//BothDB/2DBSample/RequestMessage]
         SENT BY INITIATOR,
       [//BothDB/2DBSample/ReplyMessage]
         SENT BY TARGET
      );
GO

--Create the target queue and service
CREATE QUEUE TargetQueue2DB;

CREATE SERVICE [//TgtDB/2DBSample/TargetService]
       ON QUEUE TargetQueue2DB
       ([//BothDB/2DBSample/SimpleContract]);
GO

--Lesson 3: Creating the Initiator Conversation Objects
--Switch to the InitiatorDB database
USE InitiatorDB;
GO

--Create the message types
CREATE MESSAGE TYPE [//BothDB/2DBSample/RequestMessage]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE [//BothDB/2DBSample/ReplyMessage]
       VALIDATION = WELL_FORMED_XML;
GO

--Create the contract
CREATE CONTRACT [//BothDB/2DBSample/SimpleContract]
      ([//BothDB/2DBSample/RequestMessage]
         SENT BY INITIATOR,
       [//BothDB/2DBSample/ReplyMessage]
         SENT BY TARGET
      );
GO

--Create the initiator queue and service
CREATE QUEUE InitiatorQueue2DB;

CREATE SERVICE [//InitDB/2DBSample/InitiatorService]
       ON QUEUE InitiatorQueue2DB;
GO

--Lesson 4: Beginning a Conversation and Transmitting Messages
--Switch to the InitiatorDB database
USE InitiatorDB;
GO

--Start a conversation and send a request message
DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
DECLARE @RequestMsg NVARCHAR(100);

BEGIN TRANSACTION;

BEGIN DIALOG @InitDlgHandle
     FROM SERVICE [//InitDB/2DBSample/InitiatorService]
     TO SERVICE N'//TgtDB/2DBSample/TargetService'
     ON CONTRACT [//BothDB/2DBSample/SimpleContract]
     WITH
         ENCRYPTION = OFF;

SELECT @RequestMsg =
   N'<RequestMsg>Message for Target service.</RequestMsg>';

SEND ON CONVERSATION @InitDlgHandle
     MESSAGE TYPE [//BothDB/2DBSample/RequestMessage]
      (@RequestMsg);

SELECT @RequestMsg AS SentRequestMsg;

COMMIT TRANSACTION;
GO

--Switch to the TargetDB database
USE TargetDB;
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
  FROM TargetQueue2DB
), TIMEOUT 1000;

SELECT @RecvReqMsg AS ReceivedRequestMsg;

IF @RecvReqMsgName =
   N'//BothDB/2DBSample/RequestMessage'
BEGIN
     DECLARE @ReplyMsg NVARCHAR(100);
     SELECT @ReplyMsg =
        N'<ReplyMsg>Message for Initiator service.</ReplyMsg>';
 
     SEND ON CONVERSATION @RecvReqDlgHandle
          MESSAGE TYPE
            [//BothDB/2DBSample/ReplyMessage] (@ReplyMsg);

     END CONVERSATION @RecvReqDlgHandle;
END

SELECT @ReplyMsg AS SentReplyMsg;

COMMIT TRANSACTION;
GO

--Switch to the InitiatorDB database
USE InitiatorDB;
GO

--Receive the reply and end the conversation
DECLARE @RecvReplyMsg NVARCHAR(100);
DECLARE @RecvReplyDlgHandle UNIQUEIDENTIFIER;

BEGIN TRANSACTION;

WAITFOR
( RECEIVE TOP(1)
    @RecvReplyDlgHandle = conversation_handle,
    @RecvReplyMsg = message_body
  FROM InitiatorQueue2DB
), TIMEOUT 1000;

END CONVERSATION @RecvReplyDlgHandle;

-- Display recieved request.
SELECT @RecvReplyMsg AS ReceivedReplyMsg;

COMMIT TRANSACTION;
GO

