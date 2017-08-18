/*
https://www.mssqltips.com/sqlservertutorial/215/command-line-deployment-tool-for-ssis-packages/
http://www.sqlservercentral.com/articles/Integration+Services+(SSIS)/101240/
https://blogs.msdn.microsoft.com/sql_service_broker/2010/07/19/external-activator-security/
http://www.dbdelta.com/service-broker-external-activator-example/
https://social.msdn.microsoft.com/Forums/sqlserver/en-US/84b727ad-197b-421d-9478-829fa75c47dd/calling-ssis-package-from-service-broker-queue-or-windows-serive?forum=sqlintegrationservices

*/

USE ODS
GO

WAITFOR DELAY '00:00:01';
GO

CREATE SCHEMA ods;
GO

GO
CREATE TABLE dbo.ssislog(
	ssislogId INT IDENTITY(1,1) NOT NULL
	,StartDate DATETIME NOT NULL
	,EndDate DATETIME NOT NULL CONSTRAINT df_SsisLog_EndDate DEFAULT (GETDATE())
	,PackageName sysname NULL
	,JobName sysname NULL
)

SELECT * FROM dbo.ssislog


USE ODS
GO

CREATE TABLE ods.BrokerLog(
	BrokerLogDate DATETIME CONSTRAINT df_BrokerLog_BrokerLogDate DEFAULT (GETDATE())
	, ConversationHandle UNIQUEIDENTIFIER
	, MessageTypeName sysname
	, MessageBody xml
)
GO

CREATE CLUSTERED INDEX cix_BrokerLog ON ods.BrokerLog(BrokerLogDate);
GO

CREATE MESSAGE TYPE CheckRegisterMessage
GO

CREATE CONTRACT	CheckRegisterContract(
	CheckRegisterMessage SENT BY ANY
)
GO
DROP QUEUE CheckRegisterNotificationQueue

CREATE QUEUE CheckRegisterNotificationQueue
CREATE QUEUE CheckRegisterInitQueue
CREATE QUEUE CheckRegisterTargetQueue
GO
DROP SERVICE CheckRegisterNotificationService
-- create event notification service
CREATE SERVICE CheckRegisterNotificationService
ON QUEUE CheckRegisterNotificationQueue
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

CREATE SERVICE CheckRegisterInitService
ON QUEUE CheckRegisterInitQueue(
	CheckRegisterContract
)
GO

CREATE ROUTE CheckRegisterNotificationRoute  
WITH SERVICE_NAME = 'CheckRegisterNotificationService',  
ADDRESS = 'LOCAL';
GO

CREATE SERVICE CheckRegisterTargetService
ON QUEUE CheckRegisterTargetQueue(
	CheckRegisterContract
)

SELECT * FROM sys.services AS s
SELECT * FROM sys.service_queues AS sq
GO

USE master
GO

CREATE LOGIN BrokerLogin WITH PASSWORD = 'Starshine1'
GO
USE ods

CREATE USER BrokerLogin FROM LOGIN BrokerLogin
GO

GRANT CONNECT TO BrokerLogin
GO

--allow RECEIVE from the notification service queue
GRANT RECEIVE ON dbo.CheckRegisterNotificationQueue TO BrokerLogin
GO

--allow VIEW DEFINITION right on the notification service
GRANT VIEW DEFINITION ON SERVICE::CheckRegisterNotificationService TO BrokerLogin
GO

--allow REFRENCES right on the notification queue schema
GRANT REFERENCES ON SCHEMA::dbo TO BrokerLogin
GO

ALTER PROC dbo.uspCheckRegisterStart(
	@PUNBR NVARCHAR(3)
	, @GRNBR NVARCHAR(3)
	, @StartDate DATETIME
	, @EndDate DATETIME
	, @ChkType01 CHAR(1) = ''
	, @ChkType02 CHAR(1) = ''
	, @ChkType03 CHAR(1) = ''
	, @ChkType04 CHAR(1) = ''
) AS
BEGIN
	DECLARE @conversation_handle UNIQUEIDENTIFIER;
	DECLARE @MessageBody XML = (
		SELECT @PUNBR AS PUNBR, @GRNBR AS GRNBR, @StartDate AS StartDate, @EndDate AS EndDate
		, @ChkType01 AS ChkType01, @ChkType02 AS ChkType02, @ChkType03 AS ChkType03, @ChkType04 AS ChkType04
		FOR XML PATH('CheckRegister')
	);

	BEGIN TRAN
		BEGIN DIALOG CONVERSATION @conversation_handle
		FROM SERVICE CheckRegisterInitService
		TO SERVICE 'CheckRegisterTargetService'
		ON CONTRACT CheckRegisterContract
		WITH ENCRYPTION = OFF;

		SEND ON CONVERSATION @conversation_handle
			MESSAGE TYPE CheckRegisterMessage(@MessageBody);
	COMMIT TRAN
END
GO

DECLARE @PUNBR NVARCHAR(3) = 'a'
	, @GRNBR NVARCHAR(3) = 'b'
	, @StartDate DATETIME = GETDATE()
	, @EndDate DATETIME = GETDATE()
	, @ChkType01 CHAR(1) = ''
	, @ChkType02 CHAR(1) = ''
	, @ChkType03 CHAR(1) = ''
	, @ChkType04 CHAR(1) = ''
	, @Result XML;
SET @Result = (
	SELECT @PUNBR AS PUNBR, @GRNBR AS GRNBR, @StartDate AS StartDate, @EndDate AS EndDate
		, @ChkType01 AS ChkType01, @ChkType02 AS ChkType02, @ChkType03 AS ChkType03, @ChkType04 AS ChkType04
	FOR XML PATH(''), ROOT('CheckRegister')
	)
--SELECT @Result.value('(CheckRegister/PUNBR)[1]', 'NVARCHAR(3)');
DECLARE @Now DATETIME = GETDATE();
--EXEC dbo.uspCheckRegisterStart @PUNBR = 'a', @GRNBR = 'b', @StartDate = @Now, @EndDate = @Now, @ChkType01 = ''
--	, @ChkType02 = '', @ChkType03 = '', @ChkType04 = ''

USE ODS
GO
	SELECT * FROM dbo.CheckRegisterTargetQueue
	SELECT * FROM dbo.CheckRegisterInitQueue
	SELECT * FROM dbo.CheckRegisterNotificationQueue
	SELECT * FROM msdb.dbo.SsisLog


SELECT * FROM sys.events
SELECT * FROM sys.event_notifications
SELECT * FROM sys.server_event_notifications
SELECT * FROM sys.conversation_endpoints AS ce
SELECT * FROM sys.routes
SELECT * FROM sys.transmission_queue AS tq

END CONVERSATION 'FB7E644C-8559-E611-8291-ECB1D7459293'

SELECT * FROM msdb.dbo.Ssislog AS s

-- DROP EVENT NOTIFICATION CaptureErrorLogEvents on server
CREATE EVENT NOTIFICATION CaptureErrorLogEvents
	ON SERVER
	WITH FAN_IN
	FOR ERRORLOG
	TO SERVICE 'CheckRegisterNotificationService', 'current database';
GO
-- DROP EVENT NOTIFICATION CheckRegisterNotificationEvent ON QUEUE CheckRegisterTargetQueue
CREATE EVENT NOTIFICATION CheckRegisterNotificationEvent
	ON QUEUE CheckRegisterTargetQueue
	FOR QUEUE_ACTIVATION
	TO SERVICE 'CheckRegisterNotificationService', 'current database'
GO


RAISERROR (N'Test ERRORLOG Event Notifications', 10, 1) WITH LOG;
GO

DECLARE @messages TABLE
( message_data xml );

-- Receive all the messages for the next conversation_handle from the queue into the table variable
RECEIVE cast(message_body as xml)
FROM CheckRegisterNotificationQueue
INTO @messages;

-- Parse the XML from the table variable
SELECT 
 message_data.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(128)' ) as EventType,
 message_data.value('(/EVENT_INSTANCE/PostTime)[1]', 'varchar(128)') AS PostTime,
 message_data.value('(/EVENT_INSTANCE/TextData)[1]', 'varchar(128)' ) AS TextData,
 message_data.value('(/EVENT_INSTANCE/Severity)[1]', 'varchar(128)' ) AS Severity,
 message_data.value('(/EVENT_INSTANCE/Error)[1]', 'varchar(128)' ) AS Error
FROM @messages;

-- Query the catalog to see the queue
SELECT *
FROM sys.service_queues
WHERE name = 'CheckRegisterNotificationQueue';
GO
-- Query the catalog to see the service
SELECT *
FROM sys.services
WHERE name = 'CheckRegisterNotificationService';
GO
-- Query the catalog to see the notification
SELECT * 
FROM sys.server_event_notifications 
WHERE name = 'CaptureErrorLogEvents';
GO

DROP SERVICE CheckRegisterNotificationService
DROP QUEUE CheckRegisterNotificationQueue
DROP EVENT NOTIFICATION CaptureErrorLogEvents ON SERVER
GO

CREATE QUEUE CheckRegisterNotificationQueue
GO

CREATE SERVICE CheckRegisterNotificationService
ON QUEUE CheckRegisterNotificationQueue
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

CREATE EVENT NOTIFICATION CaptureErrorLogEvents
	ON SERVER
	WITH FAN_IN
	FOR ERRORLOG
	TO SERVICE 'CheckRegisterNotificationService', 'current database';
GO

RAISERROR (N'Test ERRORLOG Event Notifications', 10, 1) WITH LOG;
GO

