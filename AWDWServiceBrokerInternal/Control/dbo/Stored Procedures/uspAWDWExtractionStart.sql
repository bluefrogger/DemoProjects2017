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
	COMMIT TRAN
END
GO