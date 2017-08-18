
-- Initiator and Target Databases
USE [Control]
USE [Staging]

-- Target Conversation objects

CREATE MESSAGE TYPE [ExtractMessage]

CREATE CONTRACT ExtractContract(
	ExtractMessage SENT BY Any
)
--DROP QUEUE ExtractTargetQueue;
--DROP SERVICE ExtractTargetService 
CREATE QUEUE ExtractTargetQueue;
CREATE SERVICE ExtractTargetService ON QUEUE ExtractTargetQueue

-- Initiator Conversation objects
USE [Control]

CREATE MESSAGE TYPE ExtractMessage
CREATE CONTRACT ExtractContract(
	ExtractMessage SENT BY ANY
)

CREATE QUEUE ExtractInitQueue;
CREATE SERVICE ExtractInitService ON QUEUE ExtractInitQueue (ExtractContract);

GO

CREATE PROC dbo.uspServiceBrokerBegin(
	@FromService sysname
	, @ToService sysname
	, @Contract sysname
	, @MessageType sysname
	, @MessageBody xml
) AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @conversation_handle UNIQUEIDENTIFIER;

	BEGIN TRAN
		BEGIN DIALOG CONVERSATION @conversation_handle
		FROM SERVICE @FromService
		TO SERVICE @ToService
		ON CONTRACT @Contract
		WITH ENCRYPTION = OFF;

	COMMIT TRAN
END
GO

SELECT * FROM dbo.LogCalendar
USE [Control]
GO

CREATE PROC dbo.uspAWDWExtractionStart
AS
BEGIN
	DECLARE @conversation_handle UNIQUEIDENTIFIER;

	BEGIN TRAN
		BEGIN DIALOG CONVERSATION @conversation_handle
		FROM SERVICE ExtractInitService
		TO SERVICE 'ExtractTargetService'
		ON CONTRACT ExtractContract
		WITH ENCRYPTION = OFF;

	DECLARE @MessageBody XML;
	DECLARE crLogCalendar CURSOR FOR
		SELECT SBMessage FROM Staging.dbo.LogCalendar;

	OPEN crLogCalendar;
	FETCH NEXT FROM crLogCalendar INTO @MessageBody;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN;
		SEND ON CONVERSATION @conversation_handle
			MESSAGE TYPE ExtractMessage(@MessageBody);
		FETCH NEXT FROM crLogCalendar INTO @MessageBody;
	END;
END
GO


ALTER PROC dbo.uspExtractTargetActivation
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @converation_handle UNIQUEIDENTIFIER;
	DECLARE @message_body XML;
	DECLARE @message_type_name sysname;

	WHILE (1 = 1)
	BEGIN
		BEGIN TRAN;
		
		WAITFOR(
			RECEIVE TOP(1)
				@converation_handle = conversation_handle
				, @message_body = CAST(message_body AS xml)
				, @message_type_name = message_type_name
			FROM dbo.ExtractTargetQueue
		), TIMEOUT 2000;

		IF (@@ROWCOUNT = 0)
		BEGIN
			ROLLBACK TRAN;
			BREAK;
		END

		IF (@message_type_name = N'ExtractMessage')
		BEGIN
			EXEC awlt2011.uspExtractAddress;

			DECLARE @AddressModifiedDate DATE = @message_body.value('(ExtractMessage/AddressModifiedDate)[1]', 'DATE');
			DECLARE @reply_message_body XML = N'' + CAST(@AddressModifiedDate AS NVARCHAR(10)) + '';
			SEND ON	CONVERSATION @converation_handle MESSAGE TYPE ExtractMessage(@reply_message_body);
		END
        ELSE IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
		BEGIN
			END CONVERSATION @converation_handle;
		END
		ELSE IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
		BEGIN
			END CONVERSATION @converation_handle;
		END

		COMMIT TRAN;
	END
END
GO


USE [Control]
GO

ALTER QUEUE dbo.ExtractTargetQueue
WITH ACTIVATION(
	STATUS = ON
    , PROCEDURE_NAME = dbo.ExtractTargetActivation
	, MAX_QUEUE_READERS = 1
	, EXECUTE AS SELF
);
GO

ALTER QUEUE dbo.ExtractInitQueue
WITH ACTIVATION(
	STATUS = ON
	, PROCEDURE_NAME = dbo.ExtractInitActivation
	, MAX_QUEUE_READERS = 1
	, EXECUTE AS SELF	
)


CREATE PROC dbo.uspExtractInitActivation
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @conversation_handle UNIQUEIDENTIFIER;
	DECLARE @message_body XML;
	DECLARE @message_type_name sysname;

	WHILE (1 = 1)
	BEGIN
		BEGIN TRAN;
			WAITFOR(
				RECEIVE TOP(1)
					@conversation_handle = conversation_handle
					, @message_body = CAST(message_body AS xml)
					, @message_type_name = message_type_name
				FROM ExtractInitQueue
			), TIMEOUT 2000;

			IF (@@ROWCOUNT = 0)
			BEGIN
				ROLLBACK TRAN;
				BREAK;
			END

			IF (@message_type_name = N'ExtractMessage')
			BEGIN
				DECLARE @AddressModifiedDate DATE = @message_body.value('(ExtractMessage\AddressModifiedDate)[1]', 'DATE')
				END CONVERSATION @conversation_handle;
			END
            ELSE IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')
			BEGIN
				END CONVERSATION @conversation_handle;
			END
            ELSE IF (@message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error')
			BEGIN
				END CONVERSATION @conversation_handle;
			END
            
		COMMIT TRAN;
	END
END



DECLARE @MessageBody XML = '<row>a</row>'
EXEC dbo.uspServiceBrokerSend 'ExtractInitService', 'ExtractTargetService', 'ExtractContract', 'ExtractMessage', @MessageBody;

SELECT * FROM [Control].dbo.ExtractInitQueue
SELECT * FROM Staging.dbo.ExtractTargetQueue

SELECT * FROM sys.transmission_queue AS tq

GRANT SEND ON SERVICE::[ExtractInitService] TO [Public];
GO
IF NOT EXISTS(
	SELECT * FROM sys.service_broker_endpoints
	WHERE name = 'AlexY10Endpoint'
)
CREATE ENDPOINT AlexY10Endpoint
STATE = STARTED
AS TCP 
(
    LISTENER_PORT = 9998
)
FOR SERVICE_BROKER
(
    AUTHENTICATION = WINDOWS,
    ENCRYPTION = DISABLED
)
GO

SELECT * FROM sys.routes
SELECT * FROM sys.service_broker_endpoints

SELECT service_broker_guid
FROM sys.databases
WHERE name = 'control'

DROP ROUTE TestRemoteRoute

DECLARE @guid NVARCHAR(36) = (SELECT CAST(service_broker_guid AS NVARCHAR(36)) FROM sys.databases WHERE name = 'Control');
DECLARE @sql NVARCHAR(500) = 
	'CREATE ROUTE TestRemoteRoute
		WITH
			SERVICE_NAME = ''ExtractInitService''
			, ADDRESS = ''tcp://AlexY10.bcnt.local:9998''
			, BROKER_INSTANCE = ''' + @guid + ''';'
EXEC(@sql);
GO

ALTER DATABASE Staging SET TRUSTWORTHY ON
ALTER DATABASE [Control] SET TRUSTWORTHY ON

SELECT LEN(NEWID())