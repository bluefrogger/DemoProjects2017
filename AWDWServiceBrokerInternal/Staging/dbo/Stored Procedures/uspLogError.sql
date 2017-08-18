CREATE PROC dbo.uspLogError(
	@Handle         UNIQUEIDENTIFIER
  , @ErrorNumber    INT
  , @ErrorSeverity  INT
  , @ErrorState     INT
  , @ErrorProcedure SYSNAME
  , @ErrorLine      INT
  , @ErrorMessage   NVARCHAR(4000))
AS
BEGIN
	BEGIN TRY
		INSERT dbo.LogError (Handle, ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage)
		VALUES (@Handle, @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage);
	END TRY
	BEGIN CATCH
		EXEC xp_logevent @ErrorNumber, @ErrorMessage;
	END CATCH;
END;
