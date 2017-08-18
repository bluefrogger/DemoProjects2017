--Lesson 1: Creating the Base Conversation Objects
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
       [//AWDB/InternalAct/RequestMessage]
       VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE
       [//AWDB/InternalAct/ReplyMessage]
       VALIDATION = WELL_FORMED_XML;
GO

--Create the contract
CREATE CONTRACT [//AWDB/InternalAct/SampleContract]
      ([//AWDB/InternalAct/RequestMessage]
       SENT BY INITIATOR,
       [//AWDB/InternalAct/ReplyMessage]
       SENT BY TARGET
      );
GO

--Create the target queue and service
CREATE QUEUE TargetQueueIntAct;

CREATE SERVICE
       [//AWDB/InternalAct/TargetService]
       ON QUEUE TargetQueueIntAct
          ([//AWDB/InternalAct/SampleContract]);
GO

--Create the initiator queue and service
CREATE QUEUE InitiatorQueueIntAct;

CREATE SERVICE
       [//AWDB/InternalAct/InitiatorService]
       ON QUEUE InitiatorQueueIntAct;
GO

--Lesson 2: Creating an Internal Activation Procedure
--Switch to the AdventureWorks2008R2 database
USE AdventureWorks2008R2;
GO

--Create an internal activation stored procedure
CREATE PROCEDURE TargetActivProc
AS
  DECLARE @RecvReqDlgHandle UNIQUEIDENTIFIER;
  DECLARE @RecvReqMsg NVARCHAR(100);
  DECLARE @RecvReqMsgName sysname;

  WHILE (1=1)
  BEGIN

    BEGIN TRANSACTION;

    WAITFOR
    ( RECEIVE TOP(1)
        @RecvReqDlgHandle = conversation_handle,
        @RecvReqMsg = message_body,
        @RecvReqMsgName = message_type_name
      FROM TargetQueueIntAct
    ), TIMEOUT 5000;

    IF (@@ROWCOUNT = 0)
    BEGIN
      ROLLBACK TRANSACTION;
      BREAK;
    END

    IF @RecvReqMsgName =
       N'//AWDB/InternalAct/RequestMessage'
    BEGIN
       DECLARE @ReplyMsg NVARCHAR(100);
       SELECT @ReplyMsg =
       N'<ReplyMsg>Message for Initiator service.</ReplyMsg>';
 
       SEND ON CONVERSATION @RecvReqDlgHandle
              MESSAGE TYPE 
              [//AWDB/InternalAct/ReplyMessage]
              (@ReplyMsg);
    END
    ELSE IF @RecvReqMsgName =
        N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
    BEGIN
       END CONVERSATION @RecvReqDlgHandle;
    END
    ELSE IF @RecvReqMsgName =
        N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
    BEGIN
       END CONVERSATION @RecvReqDlgHandle;
    END
      
    COMMIT TRANSACTION;

  END
GO

--Alter the target queue to specify internal activation
ALTER QUEUE TargetQueueIntAct
    WITH ACTIVATION
    ( STATUS = ON,
      PROCEDURE_NAME = TargetActivProc,
      MAX_QUEUE_READERS = 10,
      EXECUTE AS SELF
    );
GO

--Lesson 3: Beginning a Conversation and Transmitting Messages
--Switch to the AdventureWorks2008R2 database
USE AdventureWorks2008R2;
GO

--Begin a conversation and send a request message
DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
DECLARE @RequestMsg NVARCHAR(100);

BEGIN TRANSACTION;

BEGIN DIALOG @InitDlgHandle
     FROM SERVICE
      [//AWDB/InternalAct/InitiatorService]
     TO SERVICE
      N'//AWDB/InternalAct/TargetService'
     ON CONTRACT
      [//AWDB/InternalAct/SampleContract]
     WITH
         ENCRYPTION = OFF;

-- Send a message on the conversation
SELECT @RequestMsg =
       N'<RequestMsg>Message for Target service.</RequestMsg>';

SEND ON CONVERSATION @InitDlgHandle
     MESSAGE TYPE 
     [//AWDB/InternalAct/RequestMessage]
     (@RequestMsg);

-- Diplay sent request.
SELECT @RequestMsg AS SentRequestMsg;

COMMIT TRANSACTION;
GO

--Receive the request and send a reply
--Receive the reply and end the conversation
DECLARE @RecvReplyMsg NVARCHAR(100);
DECLARE @RecvReplyDlgHandle UNIQUEIDENTIFIER;

BEGIN TRANSACTION;

WAITFOR
( RECEIVE TOP(1)
    @RecvReplyDlgHandle = conversation_handle,
    @RecvReplyMsg = message_body
    FROM InitiatorQueueIntAct
), TIMEOUT 5000;

END CONVERSATION @RecvReplyDlgHandle;

-- Display recieved request.
SELECT @RecvReplyMsg AS ReceivedReplyMsg;

COMMIT TRANSACTION;
GO

--End the target side of the conversation

--Lesson 4: Dropping the Conversation Objects
--Switch to the AdventureWorks2008R2 database
USE AdventureWorks2008R2;
GO

--Drop the conversation objects
IF EXISTS (SELECT * FROM sys.objects
           WHERE name =
           N'TargetActivProc')
     DROP PROCEDURE TargetActivProc;

IF EXISTS (SELECT * FROM sys.services
           WHERE name =
           N'//AWDB/InternalAct/TargetService')
     DROP SERVICE
     [//AWDB/InternalAct/TargetService];

IF EXISTS (SELECT * FROM sys.service_queues
           WHERE name = N'TargetQueueIntAct')
     DROP QUEUE TargetQueueIntAct;

-- Drop the intitator queue and service if they already exist.
IF EXISTS (SELECT * FROM sys.services
           WHERE name =
           N'//AWDB/InternalAct/InitiatorService')
     DROP SERVICE
     [//AWDB/InternalAct/InitiatorService];

IF EXISTS (SELECT * FROM sys.service_queues
           WHERE name = N'InitiatorQueueIntAct')
     DROP QUEUE InitiatorQueueIntAct;

-- Drop contract and message type if they already exist.
IF EXISTS (SELECT * FROM sys.service_contracts
           WHERE name =
           N'//AWDB/InternalAct/SampleContract')
     DROP CONTRACT
     [//AWDB/InternalAct/SampleContract];

IF EXISTS (SELECT * FROM sys.service_message_types
           WHERE name =
           N'//AWDB/InternalAct/RequestMessage')
     DROP MESSAGE TYPE
     [//AWDB/InternalAct/RequestMessage];

IF EXISTS (SELECT * FROM sys.service_message_types
           WHERE name =
           N'//AWDB/InternalAct/ReplyMessage')
     DROP MESSAGE TYPE
     [//AWDB/InternalAct/ReplyMessage];
