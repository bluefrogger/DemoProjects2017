/*
	Created by Alex Yoo

	Date			Comment
	2015-07-15		1.0

	This sproc returns the contents of the United Claims table in HTML
	
	**** Parameters ****
	@Table_Name			- table/view to display
	@Schema_Name		- schema name for object
	@LimitToTop = 0		- 0 to show all, otherwise use integer between 1 and 99999
	@SortOrder = 0		- 0 ASC / 1 DESC
	@OrderColumn		- NULL to default to the first column on the object.
						  You delimit using comma
*/
SET NOCOUNT ON;
go
ALTER PROC raw.spLoadStatisticsUnitedHTML
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
	/*set parameters*/
	SET @Table_Name = 'vwStats_UnitedClaim'
	SET @Schema_Name = 'raw'
	SET @LimitToTop = 0
	SET @SortOrder = 0
	SET @OrderColumn = NULL

	/*retrieve full object name*/
	SELECT @Table_Name_VARCHAR = quotename(db_name()) + '.' + quotename(schema_name(oo.schema_id)) + '.' + quotename(oo.NAME)
	FROM sys.objects AS oo
	WHERE oo.NAME = @Table_Name
		AND schema_name(oo.schema_id) = @Schema_Name;

	/*determine number of columns on object for colspan on header row*/
	SELECT @Colspan = count(*)
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @Table_Name

	/*start creating html header code*/
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

	/*end table row HTML code*/
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


