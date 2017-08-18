CREATE PROCEDURE awlt2011.uspExtractAddressCallback(
	@Handle       UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000'
  , @ServerName   SYSNAME
  , @DatabaseName SYSNAME
  , @SchemaName   SYSNAME
  , @ObjectName   SYSNAME)
AS
	BEGIN
	BEGIN TRY
		DECLARE @SynonymName SYSNAME = 'synAddress';
		EXEC awlt2011.SynonymSwitch @Handle = @Handle, @SynonymName = @SynonymName, @ServerName = @ServerName, @DatabaseName = @DatabaseName, @SchemaName = @SchemaName, @ObjectName = @ObjectName;

		DECLARE @sql NVARCHAR(4000) = 'select '+
		(
			SELECT awlt2011.ufnOpenQueryAddress(@SynonymName)
		);

		INSERT awlt2011.uttAddress
		EXEC @sql;

		EXEC dbo.uspLogActivity @Handle = @Handle, @ProcId = @@procid, @Parameter = @Synonym, @ReturnValue = 'awlt2011.Address', @LoginName = SUSER_NAME(), @UserName = USER_NAME(), @LogStatus = 6;

		INSERT awlt2011.Address (AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate)
		SELECT AddressID , AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate
		FROM awlt2011.uttAddress;

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
