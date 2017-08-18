DECLARE @error_msg VARCHAR(4000)
   ,@error_severity SMALLINT
   ,@error_state SMALLINT;

BEGIN TRY
    SELECT  1 / 0;
END TRY
BEGIN CATCH
    THROW;
    SELECT  @error_msg = ERROR_MESSAGE()
           ,@error_severity = ERROR_SEVERITY()
           ,@error_state = ERROR_STATE();
    RAISERROR(@error_msg, @error_severity, @error_state);
END CATCH;

IF OBJECT_ID('UpdateSales', 'P') IS NOT NULL
DROP PROCEDURE UpdateSales;
GO

CREATE PROCEDURE UpdateSales
  @SalesPersonID INT,
  @SalesAmt MONEY = 0
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;
      UPDATE LastYearSales
      SET SalesLastYear = SalesLastYear + @SalesAmt
      WHERE SalesPersonID = @SalesPersonID;
    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
  END CATCH
END;
GO

/*
ERROR_NUMBER(): The number assigned to the error.
ERROR_LINE(): The line number inside the routine that caused the error.
ERROR_MESSAGE(): The error message text, which includes the values supplied for any substitutable parameters
	, such as times or object names.
ERROR_SEVERITY(): The error’s severity.
ERROR_STATE(): The error’s state number.
ERROR_PROCEDURE(): The name of the stored procedure or trigger that generated the error.
*/
