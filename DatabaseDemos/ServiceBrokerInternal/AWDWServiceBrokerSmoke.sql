USE [Control]

DECLARE @conversation_handle UNIQUEIDENTIFIER;

BEGIN DIALOG CONVERSATION @conversation_handle
FROM SERVICE ExtractInitService
TO SERVICE 'ExtractTargetService'
ON CONTRACT ExtractContract
WITH ENCRYPTION = OFF;

DECLARE @MessageBody XML = (SELECT TOP(1) SBMessage FROM Staging.dbo.LogCalendar);

SEND ON CONVERSATION 'E5C4B95F-CB55-E611-8291-ECB1D7459293'
MESSAGE TYPE ExtractMessage(@MessageBody);

PRINT @conversation_handle;

END CONVERSATION '63B50AF8-C455-E611-8291-ECB1D7459293'
END CONVERSATION 'E8C4B95F-CB55-E611-8291-ECB1D7459293'

EXEC dbo.uspAWDWExtractionStart;
GO


SELECT * FROM Staging.dbo.ExtractTargetQueue
SELECT * FROM ExtractInitQueue


USE Staging

DECLARE @converation_handle UNIQUEIDENTIFIER;
DECLARE @message_body XML;
DECLARE @message_type_name sysname;

WAITFOR(
	RECEIVE TOP(1)
		@converation_handle = conversation_handle
		, @message_body = CAST(message_body AS xml)
		, @message_type_name = message_type_name
	FROM Staging.dbo.ExtractTargetQueue
), TIMEOUT 2000;


IF (@message_type_name = N'ExtractMessage')
BEGIN
	EXEC Staging.awlt2011.uspExtractAddress;

	DECLARE @AddressModifiedDate DATE = @message_body.value('(ExtractMessage/AddressModifiedDate)[1]', 'DATE');
	DECLARE @reply_message_body XML = N'' + CAST(@AddressModifiedDate AS NVARCHAR(10)) + '';
	SEND ON	CONVERSATION @converation_handle MESSAGE TYPE ExtractMessage(@reply_message_body);
END

END CONVERSATION '63B50AF8-C455-E611-8291-ECB1D7459293'
END CONVERSATION 'E8C4B95F-CB55-E611-8291-ECB1D7459293'


SELECT * FROM Staging.sys.conversation_endpoints AS ce
SELECT * FROM sys.transmission_queue AS tq

SELECT * FROM Staging.awlt2011.Address

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