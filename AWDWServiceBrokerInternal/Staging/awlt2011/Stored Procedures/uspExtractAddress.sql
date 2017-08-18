CREATE PROCEDURE awlt2011.uspExtractAddress(
	@Handle      UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000'
  , @SynonymName SYSNAME          = 'synAddress')
AS
	BEGIN
	BEGIN TRY
		DECLARE @SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@@procid);
		DECLARE @sql NVARCHAR(4000) = 'select * from '+
		(
			SELECT awlt2011.ufnOpenQueryAddress(@SynonymName)
		);

		DECLARE @uttAddress awlt2011.uttAddress;

		INSERT @uttAddress (AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate)
		EXEC(@sql);

		declare @LoginName nvarchar(512) = suser_name();
		declare @UserName nvarchar(512) = user_name();
		EXEC dbo.uspLogActivity @Handle = @Handle, @ProcId = @@procid, @Parameter = @SynonymName, @ReturnValue = 'awlt2011.Address', @LoginName = @LoginName, @UserName = @UserName, @LogStatus = 6;

		INSERT awlt2011.Address (AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate)
		SELECT AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate
		FROM @uttAddress;

		EXEC dbo.uspLogActivity @Handle = @Handle, @ProcId = @@procid, @Parameter = 'awlt2011.uttAddress', @ReturnValue = 'awlt2011.Address', @LoginName = @LoginName, @UserName = @UserName, @LogStatus = 6;
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
