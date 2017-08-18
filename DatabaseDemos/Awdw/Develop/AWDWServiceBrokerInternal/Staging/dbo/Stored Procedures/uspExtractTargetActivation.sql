
CREATE PROC dbo.uspExtractTargetActivation
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