CREATE FUNCTION awlt2011.ufnOpenQueryAddress
(
	@SynonymName SYSNAME
)
RETURNS NVARCHAR(4000)
AS
	BEGIN
		DECLARE @SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@@procid);
		DECLARE @BaseObjectName SYSNAME = dbo.ufnBaseObjectSynonym(@SchemaName, @SynonymName);
		DECLARE @ServerName SYSNAME = PARSENAME(@BaseObjectName, 4);
		DECLARE @ColumnList NVARCHAR(4000) = '[AddressID], [AddressLine1], [AddressLine2], [City], [StateProvince], [CountryRegion], [PostalCode], [rowguid], [ModifiedDate]';

		RETURN (
			SELECT FORMATMESSAGE('openquery(%s, ''select %s from %s.%s'')', @ServerName, @ColumnList, @SchemaName, @SynonymName)
		);
	END;
