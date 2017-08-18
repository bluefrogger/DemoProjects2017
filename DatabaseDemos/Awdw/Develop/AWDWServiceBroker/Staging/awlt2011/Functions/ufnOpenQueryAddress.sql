CREATE FUNCTION awlt2011.ufnOpenQueryAddress
(
	@SynonymName SYSNAME
)
RETURNS NVARCHAR(4000)
AS
	BEGIN
		DECLARE @SynonymSchemaName sysname = OBJECT_SCHEMA_NAME(@@procid);
		DECLARE @BaseObjectName SYSNAME = dbo.ufnBaseObjectSynonym(@SynonymSchemaName, @SynonymName);
		DECLARE @ServerName SYSNAME = PARSENAME(@BaseObjectName, 4);
		DECLARE @DatabaseName sysname = PARSENAME(@BaseObjectName, 3);
		DECLARE @SchemaName SYSNAME = PARSENAME(@BaseObjectName, 2);
		DECLARE @ObjectName SYSNAME = PARSENAME(@BaseObjectName, 1);
		DECLARE @ColumnList NVARCHAR(4000) = '[AddressID], [AddressLine1], [AddressLine2], [City], [StateProvince], [CountryRegion], [PostalCode], [rowguid], [ModifiedDate]';

		RETURN (
			SELECT FORMATMESSAGE('openquery(%s, ''select %s from %s.%s.%s'')', @ServerName, @ColumnList, @DatabaseName, @SchemaName, @ObjectName)
		);
	END;
