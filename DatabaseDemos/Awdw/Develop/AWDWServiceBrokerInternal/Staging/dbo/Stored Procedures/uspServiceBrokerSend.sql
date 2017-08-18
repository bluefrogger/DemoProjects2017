CREATE PROC dbo.uspServiceBrokerSend(
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

		SEND ON CONVERSATION @conversation_handle
		MESSAGE TYPE @MessageType(@MessageBody)
	COMMIT TRAN
END
GO
