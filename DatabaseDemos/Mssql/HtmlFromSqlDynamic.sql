/*
20150707 Html dynamic
Created by Thomas Schutte

Version 1.0		2015-06-17

This script returns the contents of a table in HTML code. 

***** Note ****
Due to limitations of dynamic SQL to 4000 characters the object you choose can only have a specific amount of columns 
for this code to work in SSMS. However, theoretically you can create the code and pick it up through SSIS assigning it 
to a variable and execute it that way.

**** Parameters ****
@Table_Name			- the table/view you want to display
@Schema_Name		- the schema name for the object
@LimitToTop = 0		- 0 to show all, otherwise use integer between 1 and 99999
@SortOrder = 0		- 0 ASC / 1 DESC
@OrderColumn		- NULL to default to the first column on the object, otherwise specify. 
					  You can specify more than one column, delimit using comma as you would
					  in a SQL statement
					  
*/

/* declare variables */
DECLARE @Table_Name SYSNAME
	  , @Schema_Name SYSNAME
	  , @Table_Name_VARCHAR VARCHAR(1000)
	  , @HTML VARCHAR(MAX)
	  , @SQL NVARCHAR(4000)
	  , @PARAM NVARCHAR(4000)
	  , @LimitToTop INT
	  , @Colspan INT
	  , @SortOrder INT
	  , @OrderColumn VARCHAR(1000)

/* set parameters */
SET @Table_Name = 'vwStats_HF_P14'
SET @Schema_Name = 'raw'
SET @LimitToTop = 0
SET @SortOrder = 0
SET @OrderColumn = NULL

/* retrieve full object name */
SELECT @Table_Name_VARCHAR = QUOTENAME(DB_NAME()) + '.' + QUOTENAME(SCHEMA_NAME(oo.schema_id)) + '.' + QUOTENAME(oo.name)
FROM sys.objects oo
WHERE oo.name = @Table_Name
	AND SCHEMA_NAME(oo.schema_id) = @Schema_Name;

/* determine number of columns on object, needed for colspan on header row */
SELECT @Colspan = COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @Table_Name

/* start creating html code */
SET @HTML = '<html>' + CHAR(10) +
			REPLICATE(CHAR(9), 1) + '<head></head>' + CHAR(10) + 
			REPLICATE(CHAR(9), 1) + '<title>' + QUOTENAME(@@SERVERNAME) + '.' + @Table_Name_VARCHAR + '</title>' + CHAR(10) +
			REPLICATE(CHAR(9), 1) + '<body>' + CHAR(10) +
			REPLICATE(CHAR(9), 2) + '<table>' + CHAR(10) +
			REPLICATE(CHAR(9), 3) + '<tr style="background-color: #5D7B9D; font-weight: bold; color: white; font-size: 25px;">' + CHAR(10) +
			REPLICATE(CHAR(9), 4) + '<td colspan="' + CAST(@Colspan AS VARCHAR(3)) + '">' + QUOTENAME(@@SERVERNAME) + '.' + @Table_Name_VARCHAR + '</td>' + CHAR(10) +
			REPLICATE(CHAR(9), 3) + '</tr>' + CHAR(10) +
			REPLICATE(CHAR(9), 3) + '<tr style="background-color: #5D7B9D; font-weight: bold; color: white;">' + CHAR(10)

/* create header row with column names in HTML table */
SELECT @HTML = @HTML + REPLICATE(CHAR(9), 4) + '<td>' + cc.name + '</td>' + CHAR(10)
FROM sys.objects oo
INNER JOIN sys.columns cc
	ON oo.object_id = cc.object_id
WHERE oo.name = @Table_Name
	AND SCHEMA_NAME(oo.schema_id) = @Schema_Name
ORDER BY cc.column_id

/* add HTML code */
SET @HTML = @HTML + REPLICATE(CHAR(9), 3) + '</tr>'

/* create dyamic SQL code to fill HTML table with data */
SELECT @SQL = 'SELECT ' + ISNULL('TOP ' + CAST(NULLIF(@LimitToTop,0) AS VARCHAR(5)),'') + ' @HTML = @HTML + CHAR(10) + REPLICATE(CHAR(9), 3) ' + 
						'+ CASE ' + 
							'WHEN ROW_NUMBER() OVER (ORDER BY ' + ISNULL(@OrderColumn, (SELECT QUOTENAME(cc.name) 
																   FROM sys.objects oo 
																   INNER JOIN sys.columns cc 
																	   ON oo.object_id= cc.object_id 
																   WHERE oo.name = @Table_Name 
																	   AND cc.column_id = 1)) 
																+ ' ' + CASE WHEN @SortOrder = 1 THEN 'DESC' ELSE '' END 
																+ ') % 2 = 1 THEN ''<tr style="background-color: #F7F6F3">'' ' + 
							'ELSE ''<tr>'' END + CHAR(10) + ' 
			   + REPLACE(
						REPLACE(
							(SELECT QUOTENAME(cc.name)
							 FROM sys.objects oo
							 INNER JOIN sys.columns cc
								  ON oo.object_id = cc.object_id
							 WHERE oo.name = @Table_Name
							 ORDER BY cc.column_id
							 FOR XML PATH (''))
							,'[','REPLICATE(CHAR(9),4) + ''<td>'' + ISNULL(CAST([')						
						,']' ,'] AS VARCHAR(MAX)), '''') + ''</td>'' + CHAR(10) + ')
			   + 'REPLICATE(CHAR(9), 3) + ''</tr>'' ' 
			   + 'FROM ' + @Table_Name_VARCHAR

/* declare parameters for sp_executesql */
SET @PARAM = '@HTML VARCHAR(MAX) OUTPUT' 

/* execute dynamic sql */
EXEC sp_executesql @SQL, @PARAM, @HTML OUTPUT

/* add HTML code */
SELECT @HTML = @HTML + CHAR(10) 
					 + REPLICATE(CHAR(9), 2) + '</table>' + CHAR(10) +
					 + REPLICATE(CHAR(9), 1) + '</body>' + CHAR(10) +
					 + '</html>'
			
			
/* print HTML code. If this code is too long SSMS will truncate it. 
   As a workaround save @HTML to a table (VARCHAR(MAX) for target column) and pick up the output from there */
PRINT @HTML
