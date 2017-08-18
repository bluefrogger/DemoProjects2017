use staging

select * from dbo.LogActivity
select * from dbo.LogError

go
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

		EXEC dbo.uspLogError (@Handle, @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage);
	END CATCH;
END;

go	
select convert(time(0), getdate()), convert(time, getdate())
select * from sys.server_principals
select cast(cast(0 as binary(16)) as uniqueidentifier)

go
CREATE PROC dbo.TestProc
AS
	BEGIN
		SELECT @@procid, OBJECT_NAME(@@procid);
	END;

EXEC dbo.TestProc;

go
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
