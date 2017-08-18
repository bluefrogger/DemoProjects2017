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
				DECLARE @AddressModifiedDate DATE = @message_body.value('(ExtractMessage/AddressModifiedDate)[1]', 'DATE')
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