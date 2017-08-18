
DECLARE @Handle      UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000'
  , @SynonymName SYSNAME          = 'synAddress'

DECLARE @SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@@procid);
DECLARE @sql NVARCHAR(4000) = 'select * from '+
(
	SELECT awlt2011.ufnOpenQueryAddress(@SynonymName)
);

PRINT @sql

DECLARE @uttAddress awlt2011.uttAddress;

INSERT @uttAddress (AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate)
EXEC(@sql);

declare @LoginName nvarchar(512) = suser_name();
declare @UserName nvarchar(512) = user_name();
EXEC dbo.uspLogActivity @Handle = @Handle, @ProcId = @@procid, @Parameter = @SynonymName, @ReturnValue = 'awlt2011.Address', @LoginName = @LoginName, @UserName = @UserName, @LogStatus = 6;

INSERT awlt2011.Address (AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate)
SELECT AddressID, AddressLine1, AddressLine2, City, StateProvince, CountryRegion, PostalCode, rowguid, ModifiedDate
FROM @uttAddress

EXEC dbo.uspLogActivity @Handle = @Handle, @ProcId = @@procid, @Parameter = 'awlt2011.uttAddress', @ReturnValue = 'awlt2011.Address', @LoginName = @LoginName, @UserName = @UserName, @LogStatus = 6;

TRUNCATE TABLE awlt2011.Address
