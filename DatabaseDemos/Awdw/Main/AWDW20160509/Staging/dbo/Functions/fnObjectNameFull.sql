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
