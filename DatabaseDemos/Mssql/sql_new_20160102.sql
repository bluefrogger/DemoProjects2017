-- Update NFLOC not needed anymore
				/*;with DirtyData as (
					select
						row_number() over (order by NFLOC) as ID
						,NFLOC
						,rtrim(case
									when charindex('NF-LOC', bcomments) > 0 then substring(bcomments, charindex('NF-LOC', bcomments), 11)
									when charindex('NFLOC', bcomments) > 0 then substring(bcomments, charindex('NFLOC', bcomments), 10)
								end) as NFLOC2
					FROM DAR_CM.prod.UAS_MLTC_Cases AS cc
					where (charindex('NF-LOC', bcomments) > 0 OR charindex('NFLOC', bcomments) > 0)
				)
				, CleanData as (
					select xx.ID, xx.Num, xx.Chr
					from support.tally as tt
					cross apply (
						SELECT dd.id
							,tt.Num
							,substring(dd.NFLOC2, tt.Num, 1) as Chr
						from DirtyData as dd
						where tt.Num <= len(dd.NFLOC2)
					) as xx
					left join support.tallychar as cc
						on xx.Chr = cc.Chr
					where patindex('%[0-9]%', xx.Chr) > 0
				)
				update dd
				set NFLOC = cast((
						select rtrim(dd.Chr)
						from CleanData as dd
						where id = cc.id
						order by dd.Num
						for xml path('')
					) as int)
				from CleanData as cc
				join DirtyData as dd
					on cc.id = dd.id
				*/

--------------------------------------------------------------------------------
-- cross apply
select object_name(object_id, db_id()) as TableName
	,column_id as rownum
into dbo.TestXA
from sys.columns
order by object_name(object_id, db_id())
	,column_id

select
	TableName
	,rownum
	,(
		select max(rownum)
		from dbo.TestXA as bb
		where bb.TableName = aa.TableName
	) as rownumMax
from dbo.TestXA as aa

select
	aa.TableName
	,aa.rownum
	,bb.rownumMax
from dbo.TestXA as aa
join (
	select TableName
		,max(rownum) as rownumMax
	from dbo.testxa
	group by TableName
) as bb
on aa.TableName = bb.TableName


select
	aa.TableName
	,aa.rownum
	,xx.rownumMax
from dbo.TestXA as aa
cross apply (
	select
		max(rownum)
	from dbo.testxa as bb
	where bb.TableName = aa.TableName
) as xx(rownumMax)

--------------------------------------------------------------------------------
-- try catch transaction
begin try
	begin tran
		select 1/0
	commit tran
	print 'operation successful'
end try
begin catch
	if @@trancount > 0
	begin
		rollback tran
		print 'error detected, all changes reversed'
	end
	SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure
end catch

BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Some code

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
        
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
END CATCH;

BEGIN TRANSACTION;

BEGIN TRY
    -- Generate a constraint violation error.
    DELETE FROM Production.Product
    WHERE ProductID = 980;
END TRY
BEGIN CATCH
    SELECT 
        ERROR_NUMBER() AS ErrorNumber
        ,ERROR_SEVERITY() AS ErrorSeverity
        ,ERROR_STATE() AS ErrorState
        ,ERROR_PROCEDURE() AS ErrorProcedure
        ,ERROR_LINE() AS ErrorLine
        ,ERROR_MESSAGE() AS ErrorMessage;

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
END CATCH;

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
GO
ALTER PROC [raw].[spLoadStatisticsUnitedHTML]
AS
BEGIN
	/*declare variables*/
	DECLARE @Table_Name SYSNAME
		,@Schema_Name SYSNAME
		,@Table_Name_VARCHAR VARCHAR(1000)
		,@LimitToTop INT
		,@Colspan INT
		,@SortOrder INT
		,@OrderColumn VARCHAR(1000)
		,@HTML VARCHAR(max)
		,@SQL NVARCHAR(4000)
		,@PARAM NVARCHAR(4000)
		,@Date DATETIME
	/*set parameters*/
	SET @Table_Name = 'vwStats_UnitedClaim'
	SET @Schema_Name = 'raw'
	SET @LimitToTop = 0
	SET @SortOrder = 0
	SET @OrderColumn = NULL
	SET @Date = getdate()

	/*retrieve full object name*/
	SELECT @Table_Name_VARCHAR = quotename(db_name()) + '.' + quotename(schema_name(oo.schema_id)) + '.' + quotename(oo.NAME)
	FROM sys.objects AS oo
	WHERE oo.NAME = @Table_Name
		AND schema_name(oo.schema_id) = @Schema_Name;

	/*determine number of columns on object for colspan on header row*/
	SELECT @Colspan = count(*)
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @Table_Name

	/*start creating html code*/
	set @HTML = '<html>' + char(10)
				+ replicate(char(9), 1) + '<head></head>' + char(10)
				+ replicate(char(9), 1) + '<title>' + quotename(@@servername) + '.' + @Table_Name_VARCHAR + '</title>' + char(10)
				+ replicate(char(9), 1) + '<body>' + char(10)
				+ replicate(char(9), 2) + '<table>' + char(10)
				+ replicate(char(9), 3) + '<tr style="background-color: #5D7B9D; color: white; font-weight: bold; ">' + char(10)
				+ replicate(char(9), 4) + '<td colspan="' + CAST(@Colspan as varchar(3)) + '">' 
										+ quotename(@@servername) + '.' + @Table_Name_VARCHAR + '</td>' + char(10)
				+ replicate(char(9), 3) + '</tr>' + char(10)
				+ replicate(char(9), 3) + '<tr style = "background-color: #5D7B9D; color: white; font-weight: bold;">' + char(10)

	/*create header row with column names in HTML table*/
	SELECT @HTML = @HTML + replicate(CHAR(9), 4) + '<td>' + cc.NAME + '</td>' + CHAR(10)
	FROM sys.objects AS oo
		JOIN sys.columns AS cc 
		ON oo.object_id = cc.object_id
	WHERE oo.NAME = @Table_Name
		AND schema_name(oo.schema_id) = @Schema_Name
	ORDER BY cc.column_id

	/*add HTML code*/
	SET @HTML = @HTML + replicate(CHAR(9), 3) + '</tr>'

	/*create dynamic SQL code to fill HTML table with data*/
	select @SQL = 'select ' + isnull('top ' + cast(nullif(@LimitToTop, 0) as varchar(5)), '')
				+ ' @HTML = @HTML + char(10) + replicate(char(9), 3) '
				+ '+ Case '
					+ 'when row_number() over (order by ' 
						+ isnull(@OrderColumn,	(select quotename(cc.name)
												from sys.objects as oo
													join sys.columns as cc
													on oo.object_id = cc.object_id
												where oo.name = @Table_Name
													and cc.column_id = 1
												)
								)
						+ ' ' + case when @SortOrder = 1 then 'desc' else '' end
						+ ') % 2 = 1 THEN ''<tr style="background-color: #F7F6F3">'' '
					+ 'else ''<tr>''
				end + char(10) + '
				+ replace(
					replace	(
								(select quotename(cc.name)
								from sys.objects as oo
									join sys.columns as cc
									on oo.object_id = cc.object_id
								where oo.name = @Table_Name
								order by cc.column_id
								for xml path(''))
								,'[', 'replicate(char(9), 4) + ''<td>'' + isnull(cast(['
							)
						, ']', '] as varchar(max)), '''') + ''</td>'' + char(10) + '
						)
				+ 'replicate(char(9), 3) + ''</tr>'' '
				+ 'FROM ' + @Table_Name_VARCHAR
				+ 'WHERE Date_Loaded = ''' + cast(@Date as varchar(50)) + ''''
	--print @sql
	/*declare parameters for sp_executesql*/
	set @PARAM = '@HTML VARCHAR(MAX) OUTPUT'

	exec sp_executesql @SQL, @PARAM, @HTML OUTPUT

	SELECT @HTML = @HTML+ CHAR(10)
						+ replicate(char(9), 2) + '</table>' + char(10)
						+ replicate(char(9), 1) + '</body>' + char(10)
						+ '</html>'

	if exists (
		select * from raw.RawDataLoadHTML 
		where source = 'UnitedClaim'
	) begin
		update raw.RawDataLoadHTML
		set HTML = @HTML
			,LoadDate = getdate()
		--output inserted.HTML
		where source = 'UnitedClaim'

		select HTML from raw.RawDataLoadHTML
		where source = 'UnitedClaim'
		--print 'update'

	end
	else begin
		insert into raw.RawDataLoadHTML (HTML, LoadDate, Source)
		--output inserted.HTML
		values (@HTML, getdate(), 'UnitedClaim')
		
		select HTML from raw.RawDataLoadHTML
		where source = 'UnitedClaim'
		--print 'insert'
		
	end

end
--------------------------------------------------------------------------------
-- clean data find nth delimiter
--------------------------------------------------------------------------------
-- system start time date only
DATEADD( "day", DATEDIFF( "day", (DT_DATE) "1900-01-01", @[System::StartTime]  ) , (DT_DATE) "1900-01-01" )

--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------

ALTER PROC [raw].[spLoadStatisticsUnitedHTML]
AS
BEGIN
	/*declare variables*/
	DECLARE @Table_Name SYSNAME
		,@Schema_Name SYSNAME
		,@Table_Name_VARCHAR VARCHAR(1000)
		,@LimitToTop INT
		,@Colspan INT
		,@SortOrder INT
		,@OrderColumn VARCHAR(1000)
		,@HTML VARCHAR(max)
		,@SQL NVARCHAR(4000)
		,@PARAM NVARCHAR(4000)
		,@Date DATETIME
	/*set parameters*/
	SET @Table_Name = 'vwStats_UnitedClaim'
	SET @Schema_Name = 'raw'
	SET @LimitToTop = 0
	SET @SortOrder = 0
	SET @OrderColumn = NULL
	SET @Date = getdate()

	/*retrieve full object name*/
	SELECT @Table_Name_VARCHAR = quotename(db_name()) + '.' + quotename(schema_name(oo.schema_id)) + '.' + quotename(oo.NAME)
	FROM sys.objects AS oo
	WHERE oo.NAME = @Table_Name
		AND schema_name(oo.schema_id) = @Schema_Name;

	/*determine number of columns on object for colspan on header row*/
	SELECT @Colspan = count(*)
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @Table_Name

	/*start creating html code*/
	set @HTML = '<html>' + char(10)
				+ replicate(char(9), 1) + '<head></head>' + char(10)
				+ replicate(char(9), 1) + '<title>' + quotename(@@servername) + '.' + @Table_Name_VARCHAR + '</title>' + char(10)
				+ replicate(char(9), 1) + '<body>' + char(10)
				+ replicate(char(9), 2) + '<table>' + char(10)
				+ replicate(char(9), 3) + '<tr style="background-color: #5D7B9D; color: white; font-weight: bold; ">' + char(10)
				+ replicate(char(9), 4) + '<td colspan="' + CAST(@Colspan as varchar(3)) + '">' 
										+ quotename(@@servername) + '.' + @Table_Name_VARCHAR + '</td>' + char(10)
				+ replicate(char(9), 3) + '</tr>' + char(10)
				+ replicate(char(9), 3) + '<tr style = "background-color: #5D7B9D; color: white; font-weight: bold;">' + char(10)

	/*create header row with column names in HTML table*/
	SELECT @HTML = @HTML + replicate(CHAR(9), 4) + '<td>' + cc.NAME + '</td>' + CHAR(10)
	FROM sys.objects AS oo
		JOIN sys.columns AS cc 
		ON oo.object_id = cc.object_id
	WHERE oo.NAME = @Table_Name
		AND schema_name(oo.schema_id) = @Schema_Name
	ORDER BY cc.column_id

	/*add HTML code*/
	SET @HTML = @HTML + replicate(CHAR(9), 3) + '</tr>'

	/*create dynamic SQL code to fill HTML table with data*/
	select @SQL = 'select ' + isnull('top ' + cast(nullif(@LimitToTop, 0) as varchar(5)), '')
				+ ' @HTML = @HTML + char(10) + replicate(char(9), 3) '
				+ '+ Case '
					+ 'when row_number() over (order by ' 
						+ isnull(@OrderColumn,	(select quotename(cc.name)
												from sys.objects as oo
													join sys.columns as cc
													on oo.object_id = cc.object_id
												where oo.name = @Table_Name
													and cc.column_id = 1
												)
								)
						+ ' ' + case when @SortOrder = 1 then 'desc' else '' end
						+ ') % 2 = 1 THEN ''<tr style="background-color: #F7F6F3">'' '
					+ 'else ''<tr>''
				end + char(10) + '
				+ replace(
					replace	(
								(select quotename(cc.name)
								from sys.objects as oo
									join sys.columns as cc
									on oo.object_id = cc.object_id
								where oo.name = @Table_Name
								order by cc.column_id
								for xml path(''))
								,'[', 'replicate(char(9), 4) + ''<td>'' + isnull(cast(['
							)
						, ']', '] as varchar(max)), '''') + ''</td>'' + char(10) + '
						)
				+ 'replicate(char(9), 3) + ''</tr>'' '
				+ 'FROM ' + @Table_Name_VARCHAR
				+ 'WHERE Date_Loaded = ''' + cast(@Date as varchar(50)) + ''''
	--print @sql
	/*declare parameters for sp_executesql*/
	set @PARAM = '@HTML VARCHAR(MAX) OUTPUT'

	exec sp_executesql @SQL, @PARAM, @HTML OUTPUT

	SELECT @HTML = @HTML+ CHAR(10)
						+ replicate(char(9), 2) + '</table>' + char(10)
						+ replicate(char(9), 1) + '</body>' + char(10)
						+ '</html>'

	if exists (
		select * from raw.RawDataLoadHTML 
		where source = 'UnitedClaim'
	) begin
		update raw.RawDataLoadHTML
		set HTML = @HTML
			,LoadDate = getdate()
		--output inserted.HTML
		where source = 'UnitedClaim'

		select HTML from raw.RawDataLoadHTML
		where source = 'UnitedClaim'
		--print 'update'

	end
	else begin
		insert into raw.RawDataLoadHTML (HTML, LoadDate, Source)
		--output inserted.HTML
		values (@HTML, getdate(), 'UnitedClaim')
		
		select HTML from raw.RawDataLoadHTML
		where source = 'UnitedClaim'
		--print 'insert'
		
	end

end

--create table raw.RawDataLoadHTML (
--	ID int identity(1,1)
--	,LoadDate datetime constraint DF_LoadDate default getdate()
--	,HTML varchar(max)
--	,Source varchar(100)
--)

-- exec raw.spLoadStatisticsUnitedHTML;

--------------------------------------------------------------------------------

ALTER proc [raw].[EmblemHRALoadStatistics] (
	@Date_Received smalldatetime
	,@Date_Loaded smalldatetime
	,@File_Name varchar(255)
	,@TableName varchar(255)
)
as begin
/*
	exec [raw].[EmblemHRALoadStatistics] '2015-01-01', '2015-01-01'
		,'MONTEFIORE_CENTERS_HRAData-MEDICAID_20150423.csv'
		,'prod.TblHRAMedicaid'

*/
	declare 
		@Total_Records int 
		,@Min_DOS date
		,@Max_DOS date
		,@sql nvarchar(max)
		,@param nvarchar(max)

	set @sql = 
	N'select 
		@Total_Records_out = count(*)
		,@Min_DOS_out = min(FileDate)
		,@Max_DOS_out = max(FileDate)
	from DAR_CM.' + @TableName

	set @param = N'@Total_Records_out int output
				,@Min_DOS_out date output
				,@Max_DOS_out date output'
				
	exec sp_executesql @sql
					,@param
					,@Total_Records_out = @Total_Records output
					,@Min_DOS_out = @Min_DOS output
					,@Max_DOS_out = @Max_DOS output
---------------------------------------------------------------------------------