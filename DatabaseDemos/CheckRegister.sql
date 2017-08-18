/*
	Author: Alex Yoo
	Content: Register file loading service set up
	Usage: Agent or external activator service
*/

CREATE MESSAGE TYPE CheckRegisterMessage
CREATE CONTRACT	CheckRegisterContract(
	CheckRegisterMessage SENT BY ANY
)
GO

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
GO

CREATE EVENT NOTIFICATION CheckRegisterNotificationEvent
	ON QUEUE CheckRegisterTargetQueue
	FOR QUEUE_ACTIVATION
	TO SERVICE 'CheckRegisterNotificationService', 'current database'

CREATE EVENT NOTIFICATION CaptureErrorLogEvents
	ON SERVER
	WITH FAN_IN
	FOR ERRORLOG
	TO SERVICE 'CheckRegisterNotificationService', 'current database';
GO

CREATE PROC dbo.uspCheckRegisterStart(
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

