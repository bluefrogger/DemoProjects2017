CREATE PROC awlt2011.SynonymSwitch(
	@Handle       UNIQUEIDENTIFIER
  , @SynonymName  SYSNAME
  , @ServerName   SYSNAME
  , @DatabaseName SYSNAME)
AS
BEGIN
	BEGIN TRY
		DECLARE @ErrorNumber INT = 60000;
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorState INT = 0;
		IF NOT EXISTS (SELECT * FROM sys.servers WHERE name = @ServerName)
			THROW @ErrorNumber, @ErrorMessage, @ErrorState;

		IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = @DatabaseName)
			THROW @ErrorNumber, @ErrorMessage, @ErrorState;

		IF NOT EXISTS (SELECT * FROM sys.synonyms WHERE name = @SynonymName)
			THROW @ErrorNumber, @ErrorMessage, @ErrorState;

		DECLARE @SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@@procid);
		DECLARE @BaseObjectOld SYSNAME = dbo.ufnBaseObjectSynonym
		(@SchemaName, @SynonymName);
		DECLARE @ObjectName SYSNAME = PARSENAME(@BaseObjectOld, 1);
		DECLARE @BaseObjectNew SYSNAME = FORMATMESSAGE('%s.%s.%s.%s', @ServerName, @DatabaseName, @SchemaName, @ObjectName);

		IF @BaseObjectOld <> @BaseObjectNew
		BEGIN
			DECLARE @sql NVARCHAR(4000) = 
				'drop synonym ' + @SchemaName + '.' + @SynonymName + ';' + CHAR(10)
				+'create synonym ' + @SynonymName + ' for '+@BaseObjectNew+';' + CHAR(10);
			EXEC sys.sp_executesql @stmt = @sql;
		END;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorProcedure SYSNAME = ERROR_PROCEDURE();
		DECLARE @ErrorLine INT = ERROR_LINE();

		EXEC dbo.uspLogError
			 @Handle = @Handle
		   , @ErrorNumber = @ErrorNumber
		   , @ErrorSeverity = @ErrorSeverity
		   , @ErrorState = @ErrorState
		   , @ErrorProcedure = @ErrorProcedure
		   , @ErrorLine = @ErrorLine
		   , @ErrorMessage = @ErrorMessage;
	END CATCH;
END;

go
use staging

go
:setvar ServerObjects "ServerObjects"
drop proc [awlt2011].[uspTTExtractAddress]

CREATE PROCEDURE awlt2011.uspExtractAddress(
	@Handle      UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000'
  , @SynonymName SYSNAME          = 'synAddress')
AS
	BEGIN
	BEGIN TRY
		DECLARE @SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@@procid);
		DECLARE @sql NVARCHAR(4000) = 'select '+
		(
			SELECT awlt2011.ufnOpenQueryAddress(@SynonymName)
		);

		INSERT awlt2011.uttAddress
		EXEC @sql;

		EXEC dbo.uspLogActivity @Handle = @Handle, @ProcId = @@procid, @Parameter = @Synonym, @ReturnValue = 'awlt2011.Address', @LoginName = SUSER_NAME(), @UserName = USER_NAME(), @LogStatus = 6;

		INSERT awlt2011.Address (AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate)
		SELECT AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate
		FROM awlt2011.uttAddress;
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

exec [awlt2011].[uspTTExtractAddress]
go
create function dbo.ufnZeroGuid()
returns uniqueidentifier
as
begin
	return (select cast(cast(0 as binary(16)) as uniqueidentifier));
end

declare @SynonymName sysname = 'synAddress'
--select awlt2011.ufnOpenQueryAddress(@SynonymName)
SELECT [awlt2011].[ufnOpenQueryAddress] (@SynonymName)
declare @sql nvarchar(4000) = 'select ' + (select awlt2011.ufnOpenQueryAddress(@SynonymName));

go
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
