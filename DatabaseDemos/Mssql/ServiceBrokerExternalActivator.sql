USE master;
GO

---------------------------------------------------
--- create database with Service Broker enabled ---
---------------------------------------------------
ALTER DATABASE SBEA_Example
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE SBEA_Example;
GO

CREATE DATABASE SBEA_Example;
ALTER AUTHORIZATION ON DATABASE::SBEA_Example TO sa;
GO

ALTER DATABASE SBEA_Example
SET ENABLE_BROKER;
GO

-------------------------------
--- create database objects ---
-------------------------------
USE SBEA_Example;
GO

--log table
CREATE TABLE dbo.BatchProcessLog
    (
     ConversationHandle UNIQUEIDENTIFIER NOT NULL
    ,MessageTypeName sysname NOT NULL
    ,MessageBody VARBINARY(MAX) NULL
    ,LogTime DATETIME2(3)
        NOT NULL
        CONSTRAINT DF_ServiceBrokerLog_LogTime DEFAULT ( SYSDATETIME() )
    );
CREATE CLUSTERED INDEX cdx_BatchProcessLog ON dbo.BatchProcessLog(LogTime);
GO

CREATE PROC dbo.usp_LogBatchProcessResult
---------------------------------------------
--initiator queue activated proc to process messages
---------------------------------------------
AS
    DECLARE @conversation_handle UNIQUEIDENTIFIER
       ,@message_type_name sysname
       ,@message_body VARBINARY(MAX);
    WHILE 1 = 1
        BEGIN
            WAITFOR (
				RECEIVE TOP (1)
				@conversation_handle = conversation_handle
				,@message_type_name = message_type_name
				,@message_body = message_body
				FROM dbo.BatchProcessInitiatorQueue
			), TIMEOUT 1000;
            
			IF @@ROWCOUNT = 0
                BEGIN
--exit when no more messages
                    RETURN;
                END;

--log message
            INSERT  INTO dbo.BatchProcessLog
                    ( ConversationHandle
                    ,MessageTypeName
                    ,MessageBody
                    )
            VALUES  ( @conversation_handle
                    ,@message_type_name
                    ,@message_body
                    );
            END CONVERSATION @conversation_handle;
        END;
GO

CREATE PROC dbo.usp_LaunchBatchProcess @Parameter1 INT
---------------------------------------------
--called by application to trigger batch process
--Sample Usage:
--
-- EXEC dbo.usp_LaunchBatchProcess @@Parameter1 = 1;
---------------------------------------------
AS
    DECLARE @conversation_handle UNIQUEIDENTIFIER
       ,@message_body VARBINARY(MAX);

    BEGIN TRY

        BEGIN TRAN;

        BEGIN DIALOG CONVERSATION @conversation_handle
		FROM SERVICE BatchProcessInitiatorService
		TO SERVICE 'BatchProcessTargetService'
		ON CONTRACT [DEFAULT]
		WITH
		ENCRYPTION = OFF,
		LIFETIME = 6000;

        SET @message_body = CAST(N'' + CAST(@Parameter1 AS NVARCHAR(10)) + N'' AS VARBINARY(MAX));

        SEND ON CONVERSATION @conversation_handle (@message_body);

        COMMIT;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    RETURN @@ERROR;
GO

CREATE PROC dbo.usp_GetBatchProcessParameters
--------------------------------------
--called by batch package at start ---
--------------------------------------
AS
    DECLARE @conversation_handle UNIQUEIDENTIFIER
       ,@message_body XML
       ,@message_type_name sysname
       ,@parameter1 INT;

    BEGIN TRY

        BEGIN TRAN;

        RECEIVE TOP(1)
		@conversation_handle = conversation_handle
		,@message_type_name = message_type_name
		,@message_body = message_body
		FROM dbo.BatchProcessTargetQueue;

        IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR ('No messages received from dbo.BatchProcessTargetQueue', 16, 1);
                RETURN 1;
            END;

        INSERT  INTO dbo.BatchProcessLog
                (ConversationHandle
                ,MessageTypeName
                ,MessageBody
                )
        VALUES  (@conversation_handle
                ,@message_type_name
                ,CAST(@message_body AS VARBINARY(MAX))
                );

        SET @parameter1 = @message_body.query('/Parameters/Parameter1').value('.',
                                                              'int');

        COMMIT;

        SELECT  @conversation_handle AS ConversationHandle
               ,@parameter1 AS Parameter1;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;

    RETURN @@ERROR;
GO

CREATE PROC dbo.usp_CompleteBatchProcess
    @ConversationHandle UNIQUEIDENTIFIER
   ,@ErrorMessage NVARCHAR(3000) = NULL
------------------------------------------
-- called by SSIS package at completion
-- Sample Usage:

-- normal completion:
-- EXEC dbo.usp_CompleteBatchProcess
-- @ConversationHandle = '00000000-0000-0000-0000-000000000000';

-- completed with error:
-- EXEC dbo.usp_CompleteBatchProcess
-- @ConversationHandle = '00000000-0000-0000-0000-000000000000'
-- @ErrorMessage = 'an error occurred;
------------------------------------------
AS
    IF @ErrorMessage IS NULL
        BEGIN
            END CONVERSATION @ConversationHandle;
        END
    ELSE
        BEGIN
            END CONVERSATION @ConversationHandle
WITH ERROR = 1
DESCRIPTION = @ErrorMessage;
        END;

    RETURN @@ERROR;
GO

--initiator queue with activated proc to process batch completed messages
CREATE QUEUE dbo.BatchProcessInitiatorQueue
	WITH STATUS = ON,
	ACTIVATION (
	PROCEDURE_NAME = dbo.usp_LogBatchProcessResult,
	MAX_QUEUE_READERS = 1,
	EXECUTE AS SELF );
GO

--initiator service that triggers batch process
CREATE SERVICE BatchProcessInitiatorService
ON QUEUE dbo.BatchProcessInitiatorQueue
([DEFAULT]);
GO

--queue for event notifications
CREATE QUEUE dbo.BatchProcessNotificationQueue;
GO

--service for event notifications
CREATE SERVICE BatchProcessNotificationService
ON QUEUE dbo.BatchProcessNotificationQueue
(
[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
);
GO

--target queue for batch process parameters
CREATE QUEUE dbo.BatchProcessTargetQueue;
GO

--target service for batch process parameters
CREATE SERVICE BatchProcessTargetService
ON QUEUE dbo.BatchProcessTargetQueue
([DEFAULT]);
GO

--event notification for target queue
CREATE EVENT NOTIFICATION BatchProcessTargetNotification
ON QUEUE dbo.BatchProcessTargetQueue
FOR QUEUE_ACTIVATION
TO SERVICE 'BatchProcessNotificationService' , 'current database';
GO