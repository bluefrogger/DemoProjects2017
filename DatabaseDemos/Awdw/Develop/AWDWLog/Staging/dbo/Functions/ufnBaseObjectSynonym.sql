CREATE FUNCTION dbo.ufnBaseObjectSynonym
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
