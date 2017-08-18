----------------------------------------------------------------------------------
--extended properties
SELECT QUOTENAME(DB_NAME()) + ISNULL('.' + QUOTENAME(OBJECT_SCHEMA_NAME(pp.major_id)) + '.' + QUOTENAME(OBJECT_NAME(pp.major_id)),'') ObjectName
	 , CAST(LEFT(pp.name,22) AS DATETIME) ChangeDate
	 , SUBSTRING(pp.name, 27, CHARINDEX('(', pp.name) - 28) ChangeType
	 , UPPER(REPLACE(STUFF(pp.name, 1, CHARINDEX('(', pp.name),''),')','')) ChangeUser
	 , pp.value Code	 
FROM sys.extended_properties pp
WHERE ISDATE(LEFT(pp.name,22)) = 1
ORDER BY ObjectName, ChangeDate


CREATE TRIGGER add_extended_property
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE, CREATE_VIEW, ALTER_VIEW, DROP_VIEW
AS
 
DECLARE @Command nvarchar(3750)
	  , @EventType nvarchar(200)
	  , @PostTime nvarchar(23)
	  , @UserName nvarchar(25)
	  , @SchemaName nvarchar(128)
	  , @DatabaseName nvarchar(128)
	  , @ObjectName nvarchar(128)
	  , @ObjectType nvarchar(128)
	  , @DDLCode nvarchar(100);
 
SELECT @Command			= EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]'	,'nvarchar(3750)')
	 , @EventType		= EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]'				,'nvarchar(200)')
	 , @PostTime		= EVENTDATA().value('(/EVENT_INSTANCE/PostTime)[1]'					,'nvarchar(23)')
	 , @UserName		= EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]'				,'nvarchar(100)')
	 , @SchemaName		= EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]'				,'nvarchar(128)')
	 , @DatabaseName	= EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]'				,'nvarchar(128)')
	 , @ObjectName		= EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]'				,'nvarchar(128)')
	 , @ObjectType		= EVENTDATA().value('(/EVENT_INSTANCE/ObjectType)[1]'				,'nvarchar(128)');
 
SET @DDLCode = REPLACE(@PostTime,'T',' ') + N' : ' + @EventType + N' (' + @UserName + N')';
 
IF LEFT(@EventType, 4) = 'DROP'
	BEGIN
		EXEC sys.sp_addextendedproperty 
				@name = @DDLCode								
				, @value = @Command		
				, @level0type = NULL;
	END
ELSE 
	BEGIN
		EXEC sys.sp_addextendedproperty 
				@name = @DDLCode								
				, @value = @Command		
				, @level0type = N'Schema'													
				, @level0name = @SchemaName													
				, @level1type = @ObjectType													
				, @level1name = @ObjectName;
	END;

<EVENT_INSTANCE>
  <EventType>CREATE_TABLE</EventType>
  <PostTime>2015-05-28T18:32:39.273</PostTime>
  <SPID>52</SPID>
  <ServerName>[Servername]</ServerName>
  <LoginName>[Servername]\[Username]</LoginName>
  <UserName>dbo</UserName>
  <DatabaseName>[Databasename]</DatabaseName>
  <SchemaName>dbo</SchemaName>
  <ObjectName>DDL_Trigger_Test</ObjectName>
  <ObjectType>TABLE</ObjectType>
  <TSQLCommand>
    <SetOptions ANSI_NULLS="ON" ANSI_NULL_DEFAULT="ON" ANSI_PADDING="ON" QUOTED_IDENTIFIER="ON" ENCRYPTED="FALSE" />
    <CommandText>CREATE TABLE dbo.DDL_Trigger_Test(RowID INT)</CommandText>
  </TSQLCommand>
</EVENT_INSTANCE>
----------------------------------------------------------------------------------
--You can use VALUES to create objects on the fly, see examples below. Maybe this will come in handy one day.
DECLARE @FileName varchar(200)
SET @FileName = 'March report 2015.xlsx';

/***********************************************************************/

/* as a table */
WITH months AS
(
SELECT TOP 12 RIGHT('0' + CAST(ROW_NUMBER() OVER (ORDER BY column_ID) AS VARCHAR(2)),2) MM
      , DATENAME(MONTH, DATEADD(MONTH, ROW_NUMBER() OVER (ORDER BY column_ID) -1, 0)) Month
FROM master.sys.columns
)
SELECT a.FileName, SUBSTRING(a.FileName, PATINDEX('%[0-9]%', a.FileName), 4) + mm.mm AS YYYYMM
FROM (VALUES (@FileName)) a(FileName) -- use VALUES to create a table on the fly, this is NOT limited to one column
LEFT JOIN months mm
      ON LEFT(a.FileName, 3) = LEFT(mm.Month,3);

/***********************************************************************/

/* joins */
WITH months AS
(
SELECT TOP 12 RIGHT('0' + CAST(ROW_NUMBER() OVER (ORDER BY column_ID) AS VARCHAR(2)),2) MM
      , DATENAME(MONTH, DATEADD(MONTH, ROW_NUMBER() OVER (ORDER BY column_ID) -1, 0)) Month
FROM master.sys.columns
)
      
SELECT a.FileName, SUBSTRING(a.FileName, PATINDEX('%[0-9]%', a.FileName), 4) + mm.mm AS YYYYMM
FROM months mm
INNER JOIN (VALUES (@FileName)) a(FileName)                       -- works also in JOINs
      ON LEFT(a.FileName, 3) = LEFT(mm.Month,3);

/***********************************************************************/

/* cross apply */ 
WITH months AS
(
SELECT TOP 12 RIGHT('0' + CAST(ROW_NUMBER() OVER (ORDER BY column_ID) AS VARCHAR(2)),2) MM
      , DATENAME(MONTH, DATEADD(MONTH, ROW_NUMBER() OVER (ORDER BY column_ID) -1, 0)) Month
FROM master.sys.columns
)
      
SELECT a.FileName, SUBSTRING(a.FileName, PATINDEX('%[0-9]%', a.FileName), 4) + mm.mm AS YYYYMM
FROM months mm
CROSS APPLY (VALUES (@FileName)) a(FileName)                      -- or CROSS APPLIES
WHERE LEFT(mm.Month,3) = LEFT(a.FileName,3)

/***********************************************************************/
------------------------------------------------------------------------------------------
--20150827
--I just stumbled across the neatest trick I’ve seen in a while. If you ever have to clean your data for dummy entries like ‘111111111’, or ‘AAAAAA’ (values that only have one repeating character) use this:

DECLARE @sampletable TABLE (Value varchar(20))
INSERT INTO @sampletable VALUES ('1111111'),('ABCDEF'),('AAAAAAA'),('DDD'),('88888888'),('12233')

SELECT *
FROM @sampletable
WHERE REPLACE(Value, LEFT(Value,1),'') = ''

------------------------------------------------------------------------------------------------------
--20150716 sql to html dynamic
/*

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
-------------------------------------------------------------------------------
--20150707 Html dynamic
use dar_raw_data

/*

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
/*---------------------------------------------------------------------------------------
--20141224 codesmells

The script can detect:

Avoid cross server joins
Use two part naming
Use of nolock / UNCOMMITTED READS
Use of Table / Query hints
Use of Select *
Explicit Conversion of Columnar data - Non Sargable predicates
Ordinal positions in ORDER BY Clauses
Change Of DateFormat
Change Of DateFirst
SET ROWCOUNT 
Missing Column specifications on insert
SET OPTION usage
Use 2 part naming in EXECUTE statements
SET IDENTITY_INSERT 
Use of RANGE windows in SQL Server 2012
Create table statements should specify schema
View created with ORDER
Writable cursors 
SET NOCOUNT ON should be included inside stored procedures
COUNT(*) used when EXISTS/NOT EXISTS can be more performant
use of TOP(100) percent or TOP(>9999) in a derived table
---------------------------------------------------------------------------------------------
20141224 sargable

WHERE clause a function operating on a column value. ORDER BY, GROUP BY and HAVING clauses.
The SELECT clause, on the other hand, can contain

Sargable operators: =, >, <, >=, <=, BETWEEN, LIKE without leading %

Sargable operators that rarely improve performance: <>, IN, OR, NOT IN, NOT EXISTS, NOT LIKE

Non-sargable operators: LIKE with leading wildcards

Rules of thumb
Avoid functions using table values in an SQL WHERE condition.
Avoid non-sargable predicates and replace them with sargable equivalents.

Examples[edit]

Find date values in a certain year:
Non-sargable: SELECT ... WHERE EXTRACT(YEAR FROM date) = 2012
Sargable: SELECT ... WHERE date >= '2012-01-01' AND date < '2013-01-01'

Handling NULLs:
Non-sargable: SELECT ... WHERE COALESCE(FullName, 'John Smith') = 'John Smith'
Sargable: SELECT ... WHERE (FullName = 'John Smith') OR (FullName IS NULL)

String prefix search:
Non-sargable: SELECT ... WHERE SUBSTRING(DealerName FROM 1 FOR 6) = 'Toyota'
Sargable: SELECT ... WHERE DealerName LIKE 'Toyota%'

Find rows from last 20 days:
Non-sargable: SELECT ... WHERE EXTRACT(DAY FROM (CURRENT_DATE - date)) < 20
Sargable: SELECT ... WHERE date >= (CURRENT_DATE - INTERVAL '20' DAY)
-----------------------------------------------------------------------------------------------
*/
BEGIN
DECLARE @tableHTML NVARCHAR(MAX) ;
                                SET @tableHTML =
                                  N'<table><tr><th>Hello, </th></tr></table>'+
                                  N'<table><tr><th>The following are most current GIS merge results</th></tr></table>'+
                                  N'<table><tr><th> </th></tr></table>'+
                                  N' ' +
                                  N'<table border="1">' +
                                  N'<tr><th>JobEventsLogID</th><th>JobName</th><th>JobType</th><th>JobEvent</th><th>JobDescription</th><th>JobEventDate</th><th>JobEventTime</th><th>BatchID</th><th>BatchDate</th></tr>' +
                                  CAST(( 
                                                                                                
                                


-- most current GIS merge results
                                                                                SELECT top 20 
                                                                                                 td =  JobEventsLogID,'',
                                                                                                td =  JobName,'',
                                                                                                td =  JobType,'',
                                                                                                td =  JobEvent,'',
                                                                                                td =  JobDescription,'',
                                                                                                td =  JobEventDate,'',
                                                                                                td =  JobEventTime,'',
                                                                                                td =  BatchID,'',
                                                                                                td =  BatchDate,''                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              

                                                                                FROM [dbo].[Process_JobEventsLog] AS [PJEL] 
                                                                                WHERE [PJEL].[JobName] = 'BC_SP_ProcessImportTables'
                                                                                AND [PJEL].[JobType] = 'StoredProcedure'
                                                                                AND [PJEL].[JobEvent] IN ('Start', 'Finish')
                                                                                ORDER BY [PJEL].[JobEventsLogID] DESC
  
                                FOR XML PATH('tr'),TYPE) AS NVARCHAR(MAX))+N'</table>'+
                                N'<table><tr><th> </th></tr></table>'+
                                N'<table><tr><th> Source Agent Job: BC_jb_GIS_LatestMergeResults </th></tr></table>';

                                
                                 EXEC msdb..sp_send_dbmail 
                                                 @profile_name= 'SQL2 Mail',
                                                @recipients='keithm@boonchapman.com;',
                                                @subject='BC_jb_GIS_LatestMergeResults:current GIS merge results',
                                                @body=@tableHTML,
                                                @body_format = 'HTML' ;



END
