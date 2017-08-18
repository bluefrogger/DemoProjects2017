
use Staging

go
CREATE FUNCTION dbo.fnObjectNameFull
(
	@ObjectId INT
)
RETURNS SYSNAME
AS
	BEGIN
		DECLARE @ServerName SYSNAME = @@SERVERNAME;
		DECLARE @DatabaseName SYSNAME = DB_NAME();
		DECLARE @SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@ObjectId);
		DECLARE @ObjectName SYSNAME = OBJECT_NAME(@ObjectId);
		
		DECLARE @ObjectNameFull nvarchar(512) = formatmessage('%s.%s.%s.%s', @ServerName, @DatabaseName, @SchemaName, @ObjectName);

		RETURN @ObjectNameFull;
	END;

select dbo.fnObjectNameFull(1)

go
CREATE FUNCTION dbo.fnObjectName2Part
(
	@ObjectId INT
)
RETURNS SYSNAME
AS
	BEGIN
		DECLARE @SchemaName SYSNAME = OBJECT_SCHEMA_NAME(@ObjectId);
		DECLARE @ObjectName SYSNAME = OBJECT_NAME(@ObjectId);

		DECLARE @ObjectName2Part nvarchar(256) = FORMATMESSAGE('%s.%s',@SchemaName,@ObjectName);

		RETURN @ObjectName2Part;
	END;

go
CREATE FUNCTION dbo.fnBaseObjectSynonym
(
	@SchemaName  SYSNAME
   ,@SynonymName SYSNAME
)
RETURNS NVARCHAR(512)
AS
	BEGIN
		DECLARE @result NVARCHAR(512);
		DECLARE @SchemaId INT = SCHEMA_ID(@SchemaName);

		SELECT @result = base_object_name FROM sys.synonyms WHERE schema_id = @SchemaName AND name = @SynonymName;
		RETURN @result;
	END;
GO

select dbo.fnBaseObjectSynonym('MySyn')

select cast(cast(0 as binary(16)) as uniqueidentifier)

use staging
select schema_id('dbo')
create schema test 
create synonym test.MySyn for binaryrex.awlt2012.saleslt.Product
create synonym MySyn for binaryrex.awlt2012.saleslt.Address
select * from sys.synonyms
select * from sys.schemas
select object_id('dbo.MySyn'))

CREATE FUNCTION awlt2011.OpenQueryAddress
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
