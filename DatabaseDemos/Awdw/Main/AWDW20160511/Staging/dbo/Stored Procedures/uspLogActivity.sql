CREATE PROC dbo.uspLogActivity(
	@Handle      UNIQUEIDENTIFIER
  , @ProcId      INT
  , @Parameter   NVARCHAR(4000)
  , @ReturnValue NVARCHAR(4000)
  , @LoginName   NVARCHAR(512)
  , @UserName    NVARCHAR(512)
  , @LogStatus   INT)
AS
BEGIN
	BEGIN TRY
		DECLARE @ProcName SYSNAME = OBJECT_NAME(@ProcId);

		INSERT dbo.LogActivity (Handle, ProcedureName, [Parameter], ReturnValue, LoginName, UserName, LogStatus)
		VALUES (@Handle, @ProcName, @Parameter, @ReturnValue, @LoginName, @UserName, @LogStatus);
	END TRY
	BEGIN CATCH
		DECLARE @ErrorNumber INT = ERROR_NUMBER();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();
		DECLARE @ErrorProcedure SYSNAME = ERROR_PROCEDURE();
		DECLARE @ErrorLine INT = ERROR_LINE();
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

		EXEC dbo.uspLogError @Handle = @Handle, @ErrorNumber = @ErrorNumber, @ErrorSeverity = @ErrorSeverity, @ErrorState = @ErrorState, @ErrorProcedure = @ErrorProcedure, @ErrorLine = @ErrorLine, @ErrorMessage = @ErrorMessage;
	END CATCH;
END;
