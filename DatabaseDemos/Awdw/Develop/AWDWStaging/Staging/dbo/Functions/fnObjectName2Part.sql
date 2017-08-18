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
