
SELECT * FROM sys.extended_properties AS ep

SELECT 'EXEC sp_dropextendedproperty @name = ' + QUOTENAME(ep.name, '''') 
+ ', @level0type = ''schema'', @level0name = ''dbo''' + ', @level1type = ''table'', @level1name = ' 
+ QUOTENAME(OBJECT_NAME(c.[object_id]), '''') + ', @level2type = ''column'', @level2name = ' 
+ QUOTENAME(c.name, '''') + ';' 
FROM sys.extended_properties AS ep 
INNER JOIN sys.columns AS c ON c.[object_id] = ep.major_id AND c.column_id = ep.minor_id

