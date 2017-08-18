GO
IF EXISTS (SELECT * FROM sys.tables WHERE SCHEMA_ID = 1 AND name = 'MyTest')
	DROP TABLE [dbo].[MyTest];
CREATE TABLE [dbo].[MyTest](
	[id] int);
GO

CREATE TRIGGER [trAddExtendedProperty]
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, CREATE_VIEW, ALTER_VIEW, DROP_VIEW
AS

DECLARE @EventType sysname = EVENTDATA().[value]('(/EVENT_INSTANCE/EventType)[1]', 'sysname');
DECLARE @PostTime sysname = EVENTDATA().[value]('(/EVENT_INSTANCE/PostTime)[1]', 'sysname');
DECLARE @UserName sysname = EVENTDATA().[value]('(/EVENT_INSTANCE/UserName)[1]', 'sysname');
DECLARE @DatabaseName sysname = EVENTDATA().[value]('(/EVENT_INSTANCT/DatabaseName)[1]', 'sysname');
DECLARE @SchemaName sysname = EVENTDATA().[value]('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname');
DECLARE @ObjectName sysname = EVENTDATA().[value]('(/EVENT_INSTANCE/ObjectName)[1]', 'sysname');
DECLARE @ObjectType sysname = EVENTDATA().[value]('(/EVENT_INSTANCT/ObjectType)[1]', 'sysname');
DECLARE @CommandText sysname = EVENTDATA().[value]('(/EVENT_INSTANCE/CommandText)[1]', 'sysname');

DECLARE @DDL sysname = @PostTime + '. ' + @UserName + ': ' + @EventType;

IF LEFT(@EventType, 4) = 'DROP'
	BEGIN
		EXEC [sys].[sp_addextendedproperty] @name = @DDL, @value = @CommandText, @level0type = NULL;
	END;
ELSE
	BEGIN
		EXEC [sys].[sp_addextendedproperty] @name = @DDL, @value = @CommandText;--, @level0type = N'Schema', @level0name = @SchemaName, @level1type = @ObjectType, @level1name = @ObjectName;	
	END;
GO  


DECLARE @Name sysname;

DECLARE [crExtended] CURSOR FOR 
	SELECT [name] FROM [sys].[extended_properties];
OPEN [crExtended];
FETCH NEXT FROM [crExtended] INTO @Name;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	EXEC [sys].[sp_dropextendedproperty] @name = @Name;
	FETCH NEXT FROM [crExtended] INTO @Name;
END;

CLOSE [crExtended];
DEALLOCATE [crExtended];

EXEC [sys].[sp_dropextendedproperty] @name = '2016-07-07T09:59:12.343. dbo: CREATE_TABLE';
SELECT * FROM [sys].[extended_properties];


