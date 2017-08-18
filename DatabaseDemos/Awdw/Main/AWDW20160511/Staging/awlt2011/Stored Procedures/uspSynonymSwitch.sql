CREATE PROC [awlt2011].[SynonymSwitch](
	@Handle       UNIQUEIDENTIFIER
  , @SynonymName  SYSNAME
  , @ServerName   SYSNAME
  , @DatabaseName SYSNAME
  , @SchemaName sysname
  , @ObjectName sysname)
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

		DECLARE @BaseObjectOld SYSNAME = dbo.ufnBaseObjectSynonym(@SchemaName, @SynonymName);
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
