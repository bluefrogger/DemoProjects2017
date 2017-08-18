/*
https://www.mssqltips.com/sqlservertip/3153/managing-ssis-security-with-database-roles/
http://www.dbdelta.com/category/service-broker/
http://www.databasejournal.com/features/mssql/article.php/3927171/SQL-Server-Service-Broker---External-Activation.htm
http://blog.maskalik.com/sql-server-service-broker/troubleshooting-external-activation/
http://rusanu.com/2008/08/03/understanding-queue-monitors/
https://blogs.msdn.microsoft.com/sql_service_broker/2008/07/09/real-time-data-integration-with-service-broker-and-other-sql-techniques/
http://devkimchi.com/1051/service-broker-external-activator-for-sql-server-step-by-step-5/
*/

USE ODS

DROP SERVICE CheckRegisterNotificationService
DROP QUEUE CheckRegisterNotificationQueue
DROP EVENT NOTIFICATION CaptureErrorLogEvents ON SERVER
DROP EVENT NOTIFICATION CheckRegisterNotificationEvent ON QUEUE CheckRegisterTargetQueue
DROP SERVICE CheckRegisterNotificationService 
GO

CREATE MESSAGE TYPE CheckRegisterMessage
CREATE CONTRACT	CheckRegisterContract(
	CheckRegisterMessage SENT BY ANY
)
GO

--CREATE QUEUE CheckRegisterNotificationQueue
CREATE QUEUE CheckRegisterInitQueue
CREATE QUEUE CheckRegisterTargetQueue
GO

CREATE SERVICE CheckRegisterInitService
ON QUEUE CheckRegisterInitQueue(
	CheckRegisterContract
)

CREATE SERVICE CheckRegisterTargetService
ON QUEUE CheckRegisterTargetQueue(
	CheckRegisterContract
)

--CREATE SERVICE CheckRegisterNotificationService
--ON QUEUE CheckRegisterNotificationQueue
--(
--	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
--)
--GO

--CREATE ROUTE CheckRegisterNotificationRoute  
--WITH SERVICE_NAME = 'CheckRegisterNotificationService',  
--ADDRESS = 'LOCAL';
--GO

CREATE EVENT NOTIFICATION CheckRegisterNotificationEvent
	ON QUEUE CheckRegisterTargetQueue
	FOR QUEUE_ACTIVATION
	TO SERVICE 'CheckRegisterNotificationService', 'current database'
GO

CREATE EVENT NOTIFICATION CaptureErrorLogEvents
	ON SERVER
	WITH FAN_IN
	FOR ERRORLOG
	TO SERVICE 'CheckRegisterNotificationService', 'current database';
GO

CREATE PROC dbo.SSRS_CheckRegisterInitActivation
AS
BEGIN
	DECLARE @conversation_handle UNIQUEIDENTIFIER;
	DECLARE @message_type_name sysname;
	DECLARE @message_body XML;

	WHILE (1 = 1)
	BEGIN
		BEGIN TRAN
		WAITFOR (
			RECEIVE TOP(1)
				@conversation_handle = conversation_handle
				, @message_type_name = message_type_name
				, @message_body = CAST(message_body AS XML)
			FROM dbo.CheckRegisterInitQueue
		), TIMEOUT 5000;

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRAN;
			BREAK;
		END

		IF (@message_type_name = 'CheckRegisterMessage')
			END CONVERSATION @conversation_handle;
        ELSE IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			END CONVERSATION @conversation_handle;
		ELSE IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			END CONVERSATION @conversation_handle;
		COMMIT TRAN
	END
END

ALTER QUEUE dbo.CheckRegisterInitQueue 
WITH ACTIVATION(
	STATUS = ON
	, PROCEDURE_NAME = dbo.SSRS_CheckRegisterInitActivation
	, MAX_QUEUE_READERS = 1
	, EXECUTE AS SELF
)
GO



/*
DECLARE @conversation_handle UNIQUEIDENTIFIER;
DECLARE @message_type_name sysname;
DECLARE @message_body XML;

WHILE (1 = 1)
BEGIN
	BEGIN TRAN;
	END CONVERSATION '4F0F70DE-8E5A-E611-8291-ECB1D7459293';
	
	WAITFOR (
		RECEIVE TOP(1)
			@conversation_handle = conversation_handle
			, @message_type_name = message_type_name
			, @message_body = CAST(message_body AS XML)
		FROM dbo.CheckRegisterTargetQueue
	), TIMEOUT 5000;
	PRINT @@ROWCOUNT;

	IF (@@ROWCOUNT = 0)
	BEGIN
		PRINT 'rowcount = 0'
		ROLLBACK TRAN;
		BREAK;
	END

	IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
	BEGIN
		PRINT 'enddialog'
		END CONVERSATION @conversation_handle;
		BREAK;
	END
	ELSE IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
	BEGIN
		PRINT 'error'
		END CONVERSATION @conversation_handle;
		BREAK;
	END
	COMMIT TRAN;
	PRINT 'commiting'
END
GO
*/