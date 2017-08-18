CREATE PROC dbo.uspAWDWExtractionStart
AS
BEGIN
	DECLARE @MessageBody XML;
	DECLARE crLogCalendar CURSOR FOR
	SELECT SBMessage FROM Staging.dbo.LogCalendar;

	OPEN crLogCalendar;
	FETCH NEXT FROM crLogCalendar INTO @MessageBody;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXEC dbo.uspServiceBrokerSend 'ExtractInitService', 'ExtractTargetService', 'ExtractContract', 'ExtractMessage', @MessageBody;
		FETCH NEXT FROM crLogCalendar INTO @MessageBody;
	END
END
GO
