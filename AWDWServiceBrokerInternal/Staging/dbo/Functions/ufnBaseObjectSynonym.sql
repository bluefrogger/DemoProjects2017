CREATE FUNCTION [dbo].[ufnBaseObjectSynonym]
(
	@SchemaName  SYSNAME
   ,@SynonymName SYSNAME
)
RETURNS NVARCHAR(512)
AS
	BEGIN
		DECLARE @SchemaId INT = SCHEMA_ID(@SchemaName);
		RETURN (SELECT base_object_name FROM [$(ServerObjects)].sys.synonyms WHERE schema_id = @SchemaId AND name = @SynonymName);
	END;
