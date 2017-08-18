----------------------------------------------------------------------------------------------------
--2015104 stored procedures
select * from sys.procedures
select * from sys.sql_modules
----------------------------------------------------------------------------------------------------
--20151003 statistics
dbcc show_statistics ('Sales.SalesOrder','ix_SalesOrderHeader_CustomerID')
sys.stats
sys.dm_db_stats_properties

select * from sys.stats
where object_id = object_id('Sales.SalesOrderHeader')

dbcc show_statistics ('Sales.SalesOrderHeader','IX_SalesOrderHeader_CustomerID')

select * from sys.dm_db_stats_properties(object_id('Sales.SalesOrderHeader'),5)

update statistics
sp_updatestats
----------------------------------------------------------------------------------------------------
--20151001 reindex
select *
from sys.dm_db_index_physical_stats(db_id(), object_id('Sales'),1,null,default)
order by index_id, index_level

alter index pk_votes
on dbo.Votes
rebuild with(online=on, sort_in_tempdb=on, maxdop=4, fillfactor=100)

alter index pk_votes
on dbo.Votes
reorganize;

select *
from sys.dm_db_database_page_allocations(db_id(), object_id('Sales'),1,null,default)

select count(*) from sys.fn_dblog(null, null)
where AllocUnitName = 'dbo.Sales.ixSales'
----------------------------------------------------------------------------------------------------
--20150929 indexing basics
dbcc dropcleanbuffers;

set statistics io on;
set statistics time on;
go

select
	datekey
	,sum(salesQuantity)
	,sum(salesAmount)
from dbo.FactOnlineSales as fs --with (index = ix_FactOnlineSales_DateKeyStoreKey)
where storekey = 306
	and datekey between '2009-11-01' and '2009-11-07'
group by datekey

exec sp_helpindex 'dbo.factOnlineSales'

create nonclustered index ix_FactOnlineSales_DateKeyStoreKey
on dbo.FactOnlineSales (DateKey, StoreKey)
go

/*
USE [ContosoRetailDW]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[FactOnlineSales] ([StoreKey],[DateKey])
INCLUDE ([SalesQuantity],[SalesAmount])
GO
*/

;with mykeys as (
	select OnlineSalesKey
	from dbo.FactOnlineSales as fs
	where storekey = 306
		and datekey between '2009-11-01' and '2009-11-07'
)
select
	datekey
	,sum(salesQuantity)
	,sum(salesAmount)
from dbo.FactOnlineSales as fs
	join mykeys
		on fs.OnlineSalesKey = mykeys.OnlineSalesKey
group by datekey
go

if object_id('tempdb..#mykeys') is not null
	drop table #mykeys;

create table #mykeys (
	onlinesaleskey int
)

insert #mykeys (onlinesaleskey)
	select OnlineSalesKey
	from dbo.FactOnlineSales as fs
	where datekey between '2009-11-01' and '2009-11-07'
		and StoreKey = 306;

select datekey
	,sum(salesQuantity)
	,sum(salesAmount)
from dbo.FactOnlineSales as fs
	join #mykeys
		on fs.OnlineSalesKey = #mykeys.onlinesaleskey
group by datekey
go

----------------------------------------------------------------------------------------------------
--20150912 indexing
use ContosoRetailDW

dbcc dropcleanbuffers

set statistics io on;
set statistics time on;

select datekey	
	,sum(salesQuantity)
	,sum(salesAmount)
from dbo.FactOnlineSalescdew
where storeKey = 306
	and datekey between '2009-11-01' and '2009-11-07'
group by datekey

exec sp_helpindex 'dbo.factOnlineSales'

CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[FactOnlineSales] ([DateKey])

if object_id('tempdb.dbo.#mykeys') is not null
	drop table dbo.#mykeys;
create table #mykeys (
	onlinesaleskey int
);

insert #mykeys (onlinesaleskey)
	select  onlinesaleskey
	from dbo.FactOnlineSales as fs
	where datekey between '2009-11-01' and '2009-11-07'
		and storekey = 306;

select datekey	
	,sum(salesQuantity)
	,sum(salesAmount)
from dbo.FactOnlineSales as fs
join #mykeys on fs.OnlineSalesKey = #mykeys.onlinesaleskey
where storeKey = 306
	and datekey between '2009-11-01' and '2009-11-07'
group by datekey

----------------------------------------------------------------------------------------------------
--20150909 xml nodes values
declare @xml xml;

set @xml =
	'<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
	<items>
	  <item id="1">
		<name>Item 1</name>
		<comment>This is test item one</comment>
		<quantity>10</quantity>
	  </item>
	  <item id="2">
		<name>Item 2</name>
		<comment>This is the second test item</comment>
		<quantity>5</quantity>
	  </item>
	</items>'


select
	xx.data.value('(./items/item/name)[1]', 'varchar(200)') as name_no_cross
	,aa.rootnode.value('(/items/item/name)[1]', 'varchar(200)') as item_absolute
	,aa.rootnode.value('(./item/name)[1]', 'varchar(200)') as item_context
	,bb.itemnode.value('(./name)[1]', 'varchar(200)') as item_sub
from (values (@xml)) xx(data)
cross apply xx.data.nodes('/items') aa(rootnode)
cross apply aa.rootnode.nodes('./item') bb(itemnode)

----------------------------------------------------------------------------------------------------
--Backup All Databases script with dynamic naming
declare @srvName varchar(255)
declare @dbName varchar(255)
declare @filePath varchar(255)
declare @fileName varchar(255)
declare @fileDate varchar(20)

set @srvName = replace(@@servername, '\', '.')
set @filePath = 'c:\sql\backup\'
set @fileDate = convert(varchar(20), getdate(), 112)

declare dbCursor cursor for
	select name from master.dbo.sysdatabases where dbid > 4

open dbCursor
fetch next from dbCursor into @dbName

while @@fetch_status = 0
	begin
		set @fileName = @filePath + @srvName + '_' + @dbName + '_' + @fileDate + '.bak'
		backup database @dbName to disk = @fileName

		fetch next from dbCursor into @dbName
	end

close dbCursor
deallocate dbCursor

----------------------------------------------------------------------------------------------------
--DMV for state info

--sys.dm_io_ = I/O info
select * from sys.dm_io_pending_io_requests

--sys.dm_exec_ = Session & Query info
select * from sys.dm_exec_sessions
select * from sys.dm_exec_requests

--sys.dm_db_ = Database & Index info
select * from sys.dm_db_task_space_usage
select * from sys.dm_db_index_operational_stats(null, null, null, null)
select * from sys.dm_db_index_physical_stats(DB_ID(), null, null, null, 'Detailed')

----------------------------------------------------------------------------------------------------
--Sproc to display current locks/process
exec sp_lock

--Sproc to display current activity/process
exec sp_who2

select @@spid

--DMV to view locking info
select * from sys.dm_tran_locks
go

--DMV to view blocked transactions
select * from sys.dem_exec_requests where status = 'suspended'
go

--Trace flag to log deadlocks
DBCC TRACEON(1222, -1)

----------------------------------------------------------------------------------------------------
--20150704 dbcc database console commands
use adventure12

--View tranaction log size info
DBCC sqlperf(logspace)	

--View query stats for table or indexed view
DBCC show_statistics('SalesLT.Customer', 'IX_Customer_EmailAddress')	

--View current connections user set options
DBCC useroptions	

--Rebuilds indexes on a table
--DBCC dbreindex('SalesLT.Customer')	

--Reclaims unused space from tables after variable length column dropped
--DBCC cleantable(Advenure12, 'SalesLT.Customer')
/* Clean log history
EXEC dbo.sp_purge_jobhistory
    @job_name = N'NightlyBackups' ;
*/

--Integrity check of table pages/structure
DBCC checktable('SalesLT.Customer')

--Integrity check fo filegroup structure/allocation
dbcc checkfilegroup

--Integrity check of database objects (combine checktable checkfilegroup)
dbcc checkdb(Adventure12)

--Syntax info for DBCC statement.. use '?' for list
dbcc help('checkdb')

--Turn on trace flag 610 (minimally logged inserts into indexed tables)
dbcc traceon(610)

--Turn off trace flag 610
dbcc traceoff(610)

--Check trace flag status
dbcc tracestatus(610)


----------------------------------------------------------------------------------------------------
--20150620 filegroup filetable

create table nugget.Picture (
	ID uniqueidentifier rowguidcol not null primary key
	, Data varbinary(max) filestream null
)

insert nugget.Picture
values (
	NEWID()
	, CAST('i <3VE Chocolate' as varbinary(max))
)

select * from nugget.Picture

create table nugget.PictureTable as filetable
with 
	(FileTable_Directory = 'PictureVacation')
go

select filetablerootpath()


----------------------------------------------------------------------------------------------------
--20150620 dim date table
if object_id('dbo.DimDate') is not null begin
	drop table dbo.DimDate;
end
go

create table dbo.DimDate (
	DateKey int
	, FullDate date
	, DayNumberOfWeek tinyint
	, DayNameOfWeek varchar(10)
	, DayAbbrOfWeek varchar(5)
	, DayNumberOfMonth tinyint
	, DayNumberofYear smallint
	, WeekNumberOfYear tinyint
	, MonthLongName varchar(10)
	, MonthNumberOfYear tinyint
	, CalendarQuarter tinyint
	, CalendarYear smallint
	, FiscalQuarter tinyint
	, FiscalYear smallint
	, CalendarQuarterFullName varchar(20)
	, CalendarMonthFullName varchar(20)
	, FiscalQuarterFullName varchar(20)
	, FiscalYearFullName varchar(20)
)

declare @t smallint
declare @dk int
declare @fd datetime
declare @dwNum tinyint
declare @dwName varchar(10)
declare @dwAbbr varchar(5)
declare @dayMonth tinyint
declare @dayYear smallint
declare @weekYear tinyint
declare @mName varchar(10)
declare @mNum tinyint
declare @cQtr tinyint
declare @cYr smallint
declare @fQtr tinyint
declare @fYr smallint
declare @cQName varchar(20)
declare @cMName varchar(20)
declare @fQName varchar(20)
declare @fYName varchar(20)

set @fd = '12/31/2009'

while @fd < '12/31/2019' begin

	set @fd = dateadd(d, 1, @fd)
	set @dwNum = datepart(dw, @fd)
	set @dwName = datename(dw, @fd)
	set @dayMonth = datepart(d, @fd)
	set @dayYear = datepart(y, @fd)
	set @weekYear = datepart(wk, @fd)
	set @mName = datename(m, @fd)
	set @mNum = datepart(m, @fd)
	set @cQtr = datepart(q, @fd)
	set @cYr = datepart(yy, @fd)

	set @dk = cast(cast(@cYr as char(4))
		+ case when @mNum > 9 then cast(@mNum as char(2))
			else '0' + cast(@mNum as char(1))
		end
		+ case when @dayMonth > 9 then cast(@dayMonth as char(2))
			else '0' + cast(@dayMonth as char(1))
		end as int)
	
	set @fQtr = case when @cQtr = 1 then 3
			when @cQtr = 2 then 4
			when @cQtr = 3 then 1
			when @cQtr = 4 then 2
		end
	set @fYr = case when @mNum < 7 then datepart(yy, @fd)
			else datepart(yy, dateadd(yy, 1, @fd))
		end

	set @cQName = cast(@cYr as char(4)) + ' ' + 'Q' + cast(@cQtr as char(1))
	set @cMName = @mName + ' ' + cast(@cYr as char(4))
	set @fQName = cast(@fYr as char(4)) + ' ' + 'Q' + cast(@fQtr as char(1))
	set @fYName = 'FY' + cast(@fYr as char(4))
	set @dwAbbr = case when @dwName = N'Thursday'
			then left(datename(dw, @fd), 5)
			else left(datename(dw, @fd), 3)
		end

	select @fd,@dwNum,@dwName,@dayMonth,@dayYear,@weekYear,@mName,@mNum,@cQtr,@cYr
		,@dk,@fQtr,@fYr,@cQName,@cMName,@fQName,@fYName,@dwAbbr

	insert dbo.DimDate(
		DateKey
		, FullDate
		, DayNumberOfWeek
		, DayNameOfWeek
		, DayAbbrOfWeek
		, DayNumberOfMonth
		, DayNumberofYear
		, WeekNumberOfYear
		, MonthLongName
		, MonthNumberOfYear
		, CalendarQuarter
		, CalendarYear
		, FiscalQuarter
		, FiscalYear
		, CalendarQuarterFullName
		, CalendarMonthFullName
		, FiscalQuarterFullName
		, FiscalYearFullName
	)
	select
		 @dk
		, @fd
		, @dwNum
		, @dwName
		, @dwAbbr
		, @dayMonth
		, @dayYear
		, @weekYear
		, @mName
		, @mNum
		, @cQtr
		, @cYr
		, @fQtr
		, @fYr
		, @cQName
		, @cMName
		, @fQName
		, @fYName
end

create clustered index cix_DateKey on dbo.DimDate (DateKey asc)
create index ix_FullDate on dbo.DimDate (FullDate asc, DateKey asc)
----------------------------------------------------------------------------------------------------
--20150607 hierarchy recursive cte

;with cteaa(
	soldier
	,boss
	,lvl
)
as(
	select soldier
		,boss
		,1
	from dbo.tbltemp
	where soldier = 'admiral'

	union all

	select leaf.soldier
		,leaf.boss
		,tree.lvl + 1
	from dbo.tbltemp as leaf
	join cteaa as tree
		on leaf.boss = tree.soldier
)
select *
from cteaa

----------------------------------------------------------------------------------------------------
--20150607 hierarchy table valued function

create table dbo.tbltemp (
	soldier varchar(50)
	,boss varchar(50)
	,lvl int
)

insert dbo.tbltemp(
	soldier
	,boss
	,lvl
)
values('admiral','',1)
	,('land general','admiral',2)
	,('sea general','admiral',2)
	,('kernel','land general',3)
	,('captain','land general',3)
	,('major','sea general',3)	
	,('master','sea general',3)
	,('lieutenant','captain',4)
	,('medic','captain',4)
	,('corporal','captain',4)
	,('chief','master',4)
	,('seal','master',4)
	,('delta','master',4)
	,('spartan','master',4)
go

alter function dbo.fnhier(
	@parlvl int
)
returns
@tree table(
	soldier varchar(50)
	,boss varchar(50)
	,lvl int
)
as
begin

	declare @lvl int = 1

	insert @tree
	select soldier
		,boss
		,lvl
	from dbo.tbltemp
	where lvl = @parlvl

	while @@rowcount > 0
	begin

		set @lvl = @lvl + 1
		insert @tree
		select leaf.soldier, leaf.boss, @lvl
		from dbo.tbltemp as tree
		join dbo.tbltemp as leaf
			on tree.soldier = leaf.boss
		join @tree as memo
			on tree.soldier = memo.soldier
		where memo.lvl = @lvl - 1

	end
	return
end

----------------------------------------------------------------------------------------------------
--20150606 waitfor delay


declare @test table(
	id int
	,note varchar(50)
)

declare @output table(
	iid int
	,inote varchar(50)
	,did int
	,dnote varchar(50)
)

insert @test(
	id
	,note
)
values (1,'doom')
	,(2,'gloom')
	,(3,'doom')

update @test
set note = 'joy'
output inserted.*, deleted.*
into @output
where note = 'doom'

select *
from @output


----------------------------------------------------------------------------------------------------
--20150606 waitfor delay
print 'hello'
waitfor delay '00:00:02'
print 'buy'

----------------------------------------------------------------------------------------------------
--20150601 fizzbuzz
select case
	when cast(aa.num % 3 as varchar(50)) = '0' then 'fizz'
	when cast(aa.num % 5 as varchar(50)) = '0' then 'buzz'
	when cast(aa.num % 15 as varchar(50)) = '0' then 'fizzbuzz'
	else cast(aa.num as varchar(50))
end
from
(
	select row_number() over (order by (select null)) as num
	from sys.columns
) as aa

----------------------------------------------------------------------------------------------------
--20150601 running total cursor

CREATE TABLE Sales (DayCount smallint, Sales money) 
CREATE CLUSTERED INDEX ndx_DayCount ON Sales(DayCount)
INSERT Sales VALUES (1,120) 
INSERT Sales VALUES (2,60) 
INSERT Sales VALUES (3,125) 
INSERT Sales VALUES (4,40)

declare @total table (
	day int
	,sale money
	,total money
)

declare @day int
	,@sale money
	,@runningtotal money = 0

declare cursorSale cursor
for
select daycount, sales
from dbo.sales

open cursorSale

fetch next from cursorSale into @day, @sale

while @@fetch_status = 0
begin

	set @runningtotal = @runningtotal + @sale
	
	insert @total (
		day
		,sale
		,total
	)
	values (@day, @sale, @runningtotal)

	fetch next from cursorSale into @day, @sale

end

close cursorSale
deallocate cursorSale

select * from @total

--coalesce method
SELECT daycount
	,sales
	,sales + coalesce((
			SELECT sum(sales)
			FROM sales AS bb
			WHERE bb.daycount < aa.daycount
			), 0)
FROM sales AS aa
ORDER BY daycount

--cross join method
select aa.daycount
	,aa.sales
	,sum(bb.sales)
from sales as aa
cross join sales as bb
where bb.daycount <= aa.daycount
group by aa.daycount, aa.sales
order by aa.daycount, aa.daycount


----------------------------------------------------------------------------------------------------
--20150601 Recursive cte hierarchy

use food

CREATE TABLE dbo.MyEmployees
(
	EmployeeID smallint NOT NULL,
	FirstName nvarchar(30)  NOT NULL,
	LastName  nvarchar(40) NOT NULL,
	Title nvarchar(50) NOT NULL,
	DeptID smallint NOT NULL,
	ManagerID int NULL,
 CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC) 
);
-- Populate the table with values.
INSERT INTO dbo.MyEmployees VALUES 
 (1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)
,(16,  N'David',N'Bradley', N'Marketing Manager', 4, 273)
,(23,  N'Mary', N'Gibson', N'Marketing Specialist', 4, 16);

;WITH DirectReports 
AS
(
-- Anchor member definition
    SELECT *
        ,0 AS Level
    FROM dbo.MyEmployees AS e
	where managerid is null

    UNION ALL

-- Recursive member definition
    SELECT e.*
        ,Level + 1
    FROM dbo.MyEmployees AS e
    INNER JOIN DirectReports AS d
        ON e.ManagerID = d.EmployeeID
)
-- Statement that executes the CTE
SELECT *
FROM DirectReports
GO

----------------------------------------------------------------------------------------------------
--20150601 find gap islands

declare @temp table (
	num int
)

insert @temp
values (1)
		,(2)
		,(4)
		,(5)
		,(8)
		,(9)
		,(13)

declare @min int
		,@max int

select @min = min(num)
		,@max = max(num)
from @temp

;with ca as (
	select num
		,row_number() over (order by num) as rn
	from @temp as tt
)
select cur.num + 1, nxt.num - 1
from ca as cur
join ca as nxt
	on cur.rn + 1 = nxt.rn
where nxt.num - cur.num > 1

select aa.num + 1
	--,(
	--	select min(cc.num)
	--	from @temp as cc
	--	where cc.num > aa.num
	--) - 1
	,zz.num - 1
from @temp as aa
cross apply (
	select min(cc.num)
	from @temp as cc
	where cc.num > aa.num
) as zz(num)
where not exists (
	select *
	from @temp as bb
	where bb.num = aa.num + 1
)
and aa.num < @max

----------------------------------------------------------------------------------------------------
--20150512
SELECT 
	[PatientControlNumber] AS ClaimID
	,count(*)
FROM [DAR_Raw_Data].[raw].[HealthFirst_P14_History]
group by [PatientControlNumber] 
having count(distinct [MemberNumber]) > 1
----------------------------------------------------------------------------------------------------
--20150519 recursive cte for hierarchy crawl
WITH MyCTE
AS ( SELECT EmpID, FirstName, LastName, ManagerID
FROM Employee
WHERE ManagerID IS NULL
UNION ALL
SELECT EmpID, FirstName, LastName, ManagerID
FROM Employee
INNER JOIN MyCTE ON Employee.ManagerID = MyCTE.EmpID
WHERE Employee.ManagerID IS NOT NULL )
SELECT *
FROM MyCTE

----------------------------------------------------------------------------------------------------
--20150511 don't use count(*)
SELECT COUNT(*) FROM dbo.table;

SELECT SUM(rows) FROM sys.partitions 
WHERE index_id IN (0,1) AND [object_id] = …

----------------------------------------------------------------------------------------------------
--20150511
declare @order table (
	id int identity(1,1)
	,name varchar(50)
	,orderdate smalldatetime
)

insert @order (
	name
	,orderdate
)
values ('yoda', '2015-05-30')
	,('sidious', '2015-05-20')
	,('quigon', '2015-05-10')
	,('obiwan', '2015-05-01')
	,('vader', '2015-04-30')
	,('luke', '2015-04-15')
	,('leia', '2015-04-01')

select oo.*, nex.*
from @order as oo
outer apply (
	select top 1 *
	from @order as pp
	where oo.orderdate > pp.orderdate
	order by pp.orderdate desc
) nex

select oo.*, prev.*
from @order as oo
outer apply (
	select top 1 *
	from @order as pp
	where oo.orderdate < pp.orderdate
	order by pp.orderdate asc
) prev

----------------------------------------------------------------------------------------------------
--20150430
declare @T table
(
  Name_Level_Class_Section varchar(25)
)

insert into @T values
('Jacky_1_B2_23'),
('Johnhy_1_B2_24'),
('Peter_2_A5_3')

select substring(Name_Level_Class_Section, P2.Pos + 1, P3.Pos - P2.Pos - 1)
from @T
  cross apply (select (charindex('_', Name_Level_Class_Section))) as P1(Pos)
  cross apply (select (charindex('_', Name_Level_Class_Section, P1.Pos+1))) as P2(Pos)
  cross apply (select (charindex('_', Name_Level_Class_Section, P2.Pos+1))) as P3(Pos)
----------------------------------------------------------------------------------------------------
--20150429
sp_msforeachdb 'select "?" AS db, * from [?].sys.tables where name like ''tblhhtotal%'''

----------------------------------------------------------------------------------------------------
--20150427 unpivot cross apply
IF OBJECT_ID('tempdb..#Suppliers','U') IS NOT NULL
  DROP TABLE #Suppliers

IF EXISTS (
		SELECT table_name
		FROM DSDB.information_schema.tables
		WHERE table_name = 'tbl_vwPacoPhone'
		)
DROP TABLE dsdb.dbo.tbl_vwPacoPhone

SELECT ID, Product
    ,SuppID=ROW_NUMBER() OVER (PARTITION BY ID ORDER BY SupplierName)
    ,SupplierName, CityName
 FROM #Suppliers
  CROSS APPLY (
    VALUES (Supplier1, City1)
    ,(Supplier2, City2)
    ,(Supplier3, City3)) x(SupplierName, CityName)
 WHERE SupplierName IS NOT NULL OR CityName IS NOT NULL

SELECT UnPivotMe.FirstName, UnPivotMe.LastName, 
        CrossApplied.Question, CrossApplied.Answer
FROM UnPivotMe
CROSS APPLY (VALUES (Question1, Answer1),
                    (Question2, Answer2),
                    (Question3, Answer3),
                    (Question4, Answer4),
                    (Question5, Answer5)) 
            CrossApplied (Question, Answer)

----------------------------------------------------------------------------------------------------
--20150421
Four uses of xml:
1. run function on every row
2. shred xml
3. impivot columns
4. reuse computed columns

----------------------------------------------------------------------------------------------------
--20150421 parse delimited string
CREATE FUNCTION dbo.SplitStrings_Numbers
(
   @List       NVARCHAR(MAX),
   @Delimiter  NVARCHAR(255)
)
RETURNS TABLE
WITH SCHEMABINDING
AS
   RETURN
   (
       SELECT Item = SUBSTRING(@List, Number, 
         CHARINDEX(@Delimiter, @List + @Delimiter, Number) - Number)
       FROM dbo.tally
       WHERE Number <= CONVERT(INT, LEN(@List))
         AND SUBSTRING(@Delimiter + @List, Number, LEN(@Delimiter)) = @Delimiter
   );
GO
----------------------------------------------------------------------------------------------------
--20150421 parse delimited string
declare @string varchar(max) = 'red,blue,green,yellow'
	, @seperator char(1) = ','
	,@xml XML
declare @values TABLE (value varchar(8000))

select @XML = CAST('<root><value>' + REPLACE(@string, @seperator, '</value><value>') + '</value></root>' AS XML)

SELECT LTRIM(RTRIM(m.n.value('.[1]', 'varchar(8000)'))) AS [value]
FROM (
	VALUES (@xml)
	) t(xx)
CROSS APPLY xx.nodes('/root/value') m(n)

ALTER FUNCTION dbo.fnSplitString (@string varchar(max), @seperator char(1))
RETURNS @values TABLE (value varchar(8000))

AS

BEGIN

DECLARE @xml XML

SELECT @XML = CAST('<root><value>' + REPLACE(@string, @seperator, '</value><value>') + '</value></root>' AS XML)

INSERT INTO @values(value)
SELECT LTRIM(RTRIM(m.n.value('.[1]','varchar(8000)'))) AS [value]
FROM (VALUES(@xml)) t(xml)
CROSS APPLY xml.nodes('/root/value')m(n)

RETURN

END

----------------------------------------------------------------------------------------------------
--20150420 parse delimited string
declare @csvlist varchar(100) = 'blue,green,red'
declare @table table (columndata varchar(100))


IF RIGHT(@CSVList, 1) <> ','
	SELECT @CSVList = @CSVList + ','

DECLARE 
	@Pos BIGINT = 1
	,@OldPos BIGINT = 1

WHILE   @Pos < LEN(@CSVList)
    BEGIN
        SELECT  @Pos = CHARINDEX(',', @CSVList, @OldPos)
			
		INSERT INTO @Table
        SELECT  LTRIM(RTRIM(SUBSTRING(@CSVList, @OldPos, @Pos - @OldPos))) Col001

        SELECT  @OldPos = @Pos + 1
    END

select * from 

CREATE Function [dbo].[fn_CSVToTable] 
(
    @CSVList Varchar(max)
)
RETURNS @Table TABLE (ColumnData VARCHAR(100))
AS
BEGIN
    IF RIGHT(@CSVList, 1) <> ','
    SELECT @CSVList = @CSVList + ','

    DECLARE @Pos    BIGINT,
            @OldPos BIGINT
    SELECT  @Pos    = 1,
            @OldPos = 1

    WHILE   @Pos < LEN(@CSVList)
        BEGIN
            SELECT  @Pos = CHARINDEX(',', @CSVList, @OldPos)
            INSERT INTO @Table
            SELECT  LTRIM(RTRIM(SUBSTRING(@CSVList, @OldPos, @Pos - @OldPos))) Col001

            SELECT  @OldPos = @Pos + 1
        END

    RETURN
END
----------------------------------------------------------------------------------------------------
--20150420 remote nonnumeric characters from string
CREATE Function [fnRemoveNonNumericCharacters](@strText VARCHAR(1000))
RETURNS VARCHAR(1000)
AS
BEGIN
    WHILE PATINDEX('%[^0-9]%', @strText) > 0
    BEGIN
        SET @strText = STUFF(@strText, PATINDEX('%[^0-9]%', @strText), 1, '')
    END
    RETURN @strText
END
----------------------------------------------------------------------------------------------------
--20150415
DECLARE @FileName VARCHAR(200)

SET @FileName = 'March report 2015.xlsx';

/***********************************************************************/
/* as a table */
WITH months
AS (
	SELECT TOP 12 RIGHT('0' + CAST(ROW_NUMBER() OVER (
					ORDER BY column_ID
					) AS VARCHAR(2)), 2) MM
		,DATENAME(MONTH, DATEADD(MONTH, ROW_NUMBER() OVER (
					ORDER BY column_ID
					) - 1, 0)) Month
	FROM master.sys.columns
	)
SELECT a.FileName
	,SUBSTRING(a.FileName, PATINDEX('%[0-9]%', a.FileName), 4) + mm.mm AS YYYYMM
FROM (
	VALUES (@FileName)
	) a(FileName) -- use VALUES to create a table on the fly, this is NOT limited to one column
LEFT JOIN months mm ON LEFT(a.FileName, 3) = LEFT(mm.Month, 3);

/***********************************************************************/
/* joins */
WITH months
AS (
	SELECT TOP 12 RIGHT('0' + CAST(ROW_NUMBER() OVER (
					ORDER BY column_ID
					) AS VARCHAR(2)), 2) MM
		,DATENAME(MONTH, DATEADD(MONTH, ROW_NUMBER() OVER (
					ORDER BY column_ID
					) - 1, 0)) Month
	FROM master.sys.columns
	)
SELECT a.FileName
	,SUBSTRING(a.FileName, PATINDEX('%[0-9]%', a.FileName), 4) + mm.mm AS YYYYMM
FROM months mm
INNER JOIN (
	VALUES (@FileName)
	) a(FileName) -- works also in JOINs
	ON LEFT(a.FileName, 3) = LEFT(mm.Month, 3);

/***********************************************************************/
/* cross apply */
WITH months
AS (
	SELECT TOP 12 RIGHT('0' + CAST(ROW_NUMBER() OVER (
					ORDER BY column_ID
					) AS VARCHAR(2)), 2) MM
		,DATENAME(MONTH, DATEADD(MONTH, ROW_NUMBER() OVER (
					ORDER BY column_ID
					) - 1, 0)) Month
	FROM master.sys.columns
	)
SELECT a.FileName
	,SUBSTRING(a.FileName, PATINDEX('%[0-9]%', a.FileName), 4) + mm.mm AS YYYYMM
FROM months mm
CROSS APPLY (
	VALUES (@FileName)
	) a(FileName) -- or CROSS APPLIES
WHERE LEFT(mm.Month, 3) = LEFT(a.FileName, 3)
	/***********************************************************************/
----------------------------------------------------------------------------------------------------
--20150330

SELECT session_id
	,command
	,blocking_session_id
	,wait_type
	,wait_time
	,wait_resource
	,t.TEXT
FROM sys.dm_exec_requests
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS t
WHERE session_id > 50
	AND blocking_session_id > 0

UNION

SELECT session_id
	,''
	,''
	,''
	,''
	,''
	,t.TEXT
FROM sys.dm_exec_connections
CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS t
WHERE session_id IN (
		SELECT blocking_session_id
		FROM sys.dm_exec_requests
		WHERE blocking_session_id > 0
		)
----------------------------------------------------------------------------------------------------
--20150313
 (\_/)
(='.'=)
(")_(")
 
  @..@
 (----)
( >__< )
^^ ~~ ^^

    |\_/|
   ( ^_^ )
    )   (
() /     \
 (  )|| ||
 '~~''~''~'

           _......_
       .-'        '-.
     .'              '.
    /                  \
   /        |\          \
  ;        |V \_         ;
  |        |  ' \        |
  ;        )   ,_\       ;
  ;       /    |         ;
   \     /      \        /
    \    |       \      /
     ,    \       \    ,
      ',_  |       \_,'
         '-|  |\    |      
        ___/  |_'.  /____'
----------------------------------------------------------------------------------------------------
--20150306
sp_msforeachdb 'select "?" AS db, * from [?].sys.tables where name like ''tblhhtotal%'''
----------------------------------------------------------------------------------------------------
--20150306
DECLARE @TableName varchar(256);

SET @TableName = 'TotalPop'

DECLARE @DBName VARCHAR(256)
DECLARE @varSQL VARCHAR(512)
DECLARE @getDBName CURSOR
SET @getDBName = CURSOR FOR

SELECT name
FROM sys.databases
CREATE TABLE #TmpTable (DBName VARCHAR(256),
SchemaName VARCHAR(256),
TableName VARCHAR(256))
OPEN @getDBName
FETCH NEXT
FROM @getDBName INTO @DBName
WHILE @@FETCH_STATUS = 0
BEGIN
      BEGIN TRY
SET @varSQL = 'USE ' + @DBName + ';
INSERT INTO #TmpTable
SELECT '''+ @DBName + ''' AS DBName,
SCHEMA_NAME(schema_id) AS SchemaName,
name AS TableName
FROM sys.tables
WHERE name LIKE ''%' + @TableName + '%'''
EXEC (@varSQL)
      END TRY
      BEGIN CATCH
            SELECT ERROR_MESSAGE(), ERROR_NUMBER()
      END CATCH
FETCH NEXT
FROM @getDBName INTO @DBName
END
CLOSE @getDBName
DEALLOCATE @getDBName
SELECT *
FROM #TmpTable
DROP TABLE #TmpTable


----------------------------------------------------------------------------------------------------
20150304
sp_msforeachdb 'select "?" AS db, * from [?].sys.tables where name like ''tblhhtotal%'''

----------------------------------------------------------------------------------------------------
20150302
--column data types
    
    select tt.name
	   ,cc.name
	   ,yy.name
	   ,cc.max_length
    from sys.tables as tt
    join sys.columns as cc
	   on tt.object_id = cc.object_id
    join sys.types as yy
	   on cc.user_type_id = yy.user_type_id
    where tt.name = 'HFClaimPharmFile'

----------------------------------------------------------------------------------------------------
20150213
--This will capture instances where the procedure is explicitly referenced in the job step:

SELECT j.name 
  FROM msdb.dbo.sysjobs AS j
  WHERE EXISTS 
  (
    SELECT 1 FROM msdb.dbo.sysjobsteps AS s
      WHERE s.job_id = j.job_id
      AND s.command LIKE '%procedurename%'
  );

----------------------------------------------------------------------------------------------------
20150211
SELECT [name] AS SSISPackageName
, CONVERT(XML, CONVERT(VARBINARY(MAX), packagedata)) AS SSISPackageXML
FROM msdb.dbo.sysdtspackages
WHERE CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), packagedata)) LIKE '%MemberMart_Update%'

----------------------------------------------------------------------------------------------------
20150210

create table #temp(
	id int identity primary key
	,startdt datetime
);

insert #temp
SELECT '2014-02-18 09:20' UNION ALL SELECT '2014-02-19 05:35';

SELECT ID, StartDT
    ,TT=DATEPART(hour, DATEADD(hour, DATEDIFF(hour, 0, StartDT), 0))
    ,TD=DATEADD(day, DATEDIFF(day, 0, StartDT), 0)
FROM #Temp;

select datepart(hour,dateadd(hour,datediff(hour,0,startdt),0))
from #temp

WITH Tally (N) AS
(
    -- Tally table starting at 0
    SELECT 0 UNION ALL
    -- Now 24 more rows
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM (VALUES(0),(0),(0),(0),(0),(0)) a(n)
    CROSS JOIN (VALUES(0),(0),(0),(0)) c(n)
)
select id, startdt, dateadd(hour,n,dateadd(day,datediff(day,0,startdt),0)) as td
from #temp
cross join tally
where n between 0 and datepart(hour,dateadd(hour,datediff(hour,0,startdt),0))
order by id, td;


DECLARE @S VARCHAR(8000) = 'Aarrrgggh!';

select substring(@s,0,1)

----------------------------------------------------------------------------------------------------
20150114 

WITH Tally (N) AS
(
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.all_columns a CROSS JOIN sys.all_columns b
)
SELECT TOP 5 N
FROM Tally;

WITH Tally (n) AS
(
    -- 1000 rows
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) a(n)
    CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) b(n)
    CROSS JOIN (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) c(n)
)
SELECT *
FROM Tally;

----------------------------------------------------------------------------------------------------
20140917 transactions

--If you put SET XACT_ABORT ON before you start transaction, in case of an error, rollback will be issued automatically.
--SET XACT_ABORT ON

begin transaction

INSERT INTO TableA (id) VALUES (1)
INSERT INTO TableB (id) VALUES (1)
UPDATE TableC SET id=1 WHERE id=2

commit transaction

--If you want to do rollback yourself, use try .. catch block.
--begin transaction

begin try

  INSERT INTO TableA (id) VALUES (1)
  INSERT INTO TableB (id) VALUES (1)
  UPDATE TableC SET id=1 WHERE id=2

  commit transaction

end try

begin catch
  raiserror('Message here', 16, 1)
  rollback transaction
end catch
 

create procedure proc_name
    --declare variables
as
    set nocount on
    begin transaction
    begin try
        --do something
        commit transaction
    end try 
    begin catch
        rollback transaction
        ;throw
    end catch
go


create procedure proc_name
    --declare variables
as
    set nocount on
    set xact_abort on
    begin transaction
    --do something
    commit transaction
go
----------------------------------------------------------------------------------------------------
20141010 dynamicsql


create table #test (id int, ddate varchar(8))
insert into #test values (1,'20200101'),(2,'20200102'),(3,'20200103')

declare @sql nvarchar(1000)
    ,@col varchar(100)
    ,@date varchar(10)
    
set @col = N'id, ddate'
set @date = N'20200102'
set @sql = N'select ' + @col + N' from #test where ddate = @date'

--set @sql = 'select ' + @col + ' from stage.kpi_results '
--    + 'where kpi_yyyymm = ' + @year

exec sp_executesql @sql, N'@date varchar(8)', @date = @date

exec(@sql)
----------------------------------------------------------------------------------------------------
20141023 createtallytable

	with e1(n) as
	(
	   select 1 union all select 1 union all select 1 union all select 1 union all
	   select 1 union all select 1 union all select 1 union all select 1 union all
	   select 1 union all select 1 union all select 1 union all select 1 union all
	   select 1 union all select 1 union all select 1 union all select 1
	)
	,e2(n) as (select 1 from e1 cross join e1 as aa)
	,e3(n) as (select 1 from e2 cross join e2 as aa)
	select row_number() over(order by n) as n from e3 order by n

----------------------------------------------------------------------------------------------------
20141204 cleanupcharacters

A way to identify how dirty our data in the member mart really is (looking for non-alphabet characters)

Execute in YBCM1S1.DAR_Members

WITH specialchars AS
(
SELECT ROW_NUMBER() OVER (ORDER BY FirstName) ID
      , FirstName + LastName String
      , FirstName
      , LastName
FROM support.DW_Patients_XW
WHERE PATINDEX('%[^A-Z]%', FirstName) > 0
      OR PATINDEX('%[^A-Z]%', LastName) > 0
)
, tally AS
(
SELECT ROW_NUMBER() OVER (ORDER BY c1.column_id) N
FROM master.sys.columns c1
CROSS JOIN master.sys.columns c2
)
, chartable AS
(
SELECT 0 N, CHAR(0) [Char]
UNION ALL
SELECT N + 1, CHAR(N + 1)
FROM chartable
WHERE N < 255
)

SELECT ca.[Char]
      , COUNT(*) Occurances
      , cc.N ASCII_DEC
FROM tally tt
CROSS APPLY (SELECT ss.ID, SUBSTRING(ss.String,N,1) [Char]
                  FROM specialchars ss
                  WHERE tt.N <= LEN(ss.String)
                  ) ca
LEFT JOIN chartable cc
      ON ca.Char = cc.Char
WHERE PATINDEX('%[^A-Z]%', ca.[Char]) > 0
GROUP BY ca.[Char], cc.N
ORDER BY COUNT(*) DESC
OPTION (MAXRECURSION 0)
----------------------------------------------------------------------------------------------------
20141204 concatenate

USE AdventureWorks2008R2
SELECT      CAT.Name AS [Category],
            STUFF((    SELECT ',' + SUB.Name AS [text()]
                        – Add a comma (,) before each value
                        FROM Production.ProductSubcategory SUB
                        WHERE
                        SUB.ProductCategoryID = CAT.ProductCategoryID
                        FOR XML PATH('') – Select it as XML
                        ), 1, 1, '' )
                        – This is done to remove the first character (,)
                        – from the result
            AS [Sub Categories]
FROM  Production.ProductCategory CAT
----------------------------------------------------------------------------------------------------
20141224 parsedelimitedstringrecursivecte

DECLARE @string VARCHAR(MAX)
DECLARE @delimiter CHAR(1)
SELECT @string = 'accountant|account manager|account payable specialist|
benefits specialist|database administrator|quality assurance engineer'
SELECT @delimiter = '|';
WITH delimited_CTE(starting_character, ending_character, occurence)
AS
(
     SELECT 
     -- set starting character to 1:
          starting_character = 1
          ,ending_character = CAST(CHARINDEX(@delimiter, @string + @delimiter) AS INT)
          ,1 as occurence
UNION ALL
     SELECT 
     -- set starting character to 1 after the ending character:
          starting_character = ending_character + 1
          ,ending_character = CAST(CHARINDEX(@delimiter, @string + @delimiter, ending_character + 1) AS INT)
          ,occurence + 1
     FROM delimited_CTE
     WHERE 
     CHARINDEX(@delimiter, @string + @delimiter, ending_character + 1) <> 0
)
SELECT 
     SUBSTRING(@string, starting_character, ending_character-starting_character) AS string_values
     ,occurence
FROM delimited_CTE


/* Let's create our parsing function... */
CREATE FUNCTION dbo.dba_parseString_udf
(
          @stringToParse VARCHAR(8000)  
        , @delimiter     CHAR(1)
)
RETURNS @parsedString TABLE (stringValue VARCHAR(128))
AS
/*********************************************************************************
    Name:       dba_parseString_udf
 
    Author:     Michelle Ufford, http://sqlfool.com
 
    Purpose:    This function parses string input using a variable delimiter.
 
    Notes:      Two common delimiter values are space (' ') and comma (',')
 
    Date        Initials    Description
    ----------------------------------------------------------------------------
    2011-05-20  MFU         Initial Release
*********************************************************************************
Usage: 		
    SELECT *
	FROM dba_parseString_udf(<string>, <delimiter>);
 
Test Cases:
 
    1.  multiple strings separated by space
        SELECT * FROM dbo.dba_parseString_udf('  aaa  bbb  ccc ', ' ');
 
    2.  multiple strings separated by comma
        SELECT * FROM dbo.dba_parseString_udf(',aaa,bbb,,,ccc,', ',');
*********************************************************************************/
BEGIN
 
    /* Declare variables */
    DECLARE @trimmedString  VARCHAR(8000);
 
    /* We need to trim our string input in case the user entered extra spaces */
    SET @trimmedString = LTRIM(RTRIM(@stringToParse));
 
    /* Let's create a recursive CTE to break down our string for us */
    WITH parseCTE (StartPos, EndPos)
    AS
    (
        SELECT 1 AS StartPos
            , CHARINDEX(@delimiter, @trimmedString + @delimiter) AS EndPos
        UNION ALL
        SELECT EndPos + 1 AS StartPos
            , CharIndex(@delimiter, @trimmedString + @delimiter , EndPos + 1) AS EndPos
        FROM parseCTE
        WHERE CHARINDEX(@delimiter, @trimmedString + @delimiter, EndPos + 1) <> 0
    )
 
    /* Let's take the results and stick it in a table */  
    INSERT INTO @parsedString
    SELECT SUBSTRING(@trimmedString, StartPos, EndPos - StartPos)
    FROM parseCTE
    WHERE LEN(LTRIM(RTRIM(SUBSTRING(@trimmedString, StartPos, EndPos - StartPos)))) > 0
    OPTION (MaxRecursion 8000);
 
    RETURN;   
END
----------------------------------------------------------------------------------------------------
20141006 findgapinasequence

In MySQL and PostgreSQL:

SELECT  id + 1
FROM    mytable mo
WHERE   NOT EXISTS
        (
        SELECT  NULL
        FROM    mytable mi 
        WHERE   mi.id = mo.id + 1
        )
ORDER BY
        id
LIMIT 1
In SQL Server:

SELECT  TOP 1
        id + 1
FROM    mytable mo
WHERE   NOT EXISTS
        (
        SELECT  NULL
        FROM    mytable mi 
        WHERE   mi.id = mo.id + 1
        )
ORDER BY
        id
In Oracle:

SELECT  *
FROM    (
        SELECT  id + 1 AS gap
        FROM    mytable mo
        WHERE   NOT EXISTS
                (
                SELECT  NULL
                FROM    mytable mi 
                WHERE   mi.id = mo.id + 1
                )
        ORDER BY
                id
        )
WHERE   rownum = 1
ANSI (works everywhere, least efficient):

SELECT  MIN(id) + 1
FROM    mytable mo
WHERE   NOT EXISTS
        (
        SELECT  NULL
        FROM    mytable mi 
        WHERE   mi.id = mo.id + 1
        )

----------------------------------------------------------------------------------------------------
20140924 outputparameterstoredprocedure

declare @rowCount int
exec yourStoredProcedureName @outputparameterspOf = @rowCount output

----------------------------------------------------------------------------------------------------

20140904 pivotunpivot

SELECT 'AverageCost' AS Cost_Sorted_By_Production_Days, 
[0], [1], [2], [3], [4]
FROM
(SELECT DaysToManufacture, StandardCost 
    FROM Production.Product) AS SourceTable
PIVOT
(
AVG(StandardCost)
FOR DaysToManufacture IN ([0], [1], [2], [3], [4])
) AS PivotTable;


SELECT *
FROM (
    SELECT 
        year(invoiceDate) as [year],left(datename(month,invoicedate),3)as [month], 
        InvoiceAmount as Amount 
    FROM Invoice
) as s
PIVOT
(
    SUM(Amount)
    FOR [month] IN (jan, feb, mar, apr, 
    may, jun, jul, aug, sep, oct, nov, dec)
)AS pivot


--PIVOT the #CourseSales table data on the Course column 
SELECT *
INTO #CourseSalesPivotResult
FROM #CourseSales
PIVOT(SUM(Earning) 
      FOR Course IN ([.NET], Java)) AS PVTTable
GO
--UNPIVOT the #CourseSalesPivotResult table data 
--on the Course column    
SELECT Course, Year, Earning
FROM #CourseSalesPivotResult
UNPIVOT(Earning
      FOR Course IN ([.NET], Java)) AS UNPVTTable
----------------------------------------------------------------------------------------------------
20141121 cleanupnumberszipcode


WITH numbers AS
(
SELECT TOP 10 CAST(ROW_NUMBER() OVER (ORDER BY column_id) - 1 AS CHAR(1)) Number    -- create a table with each number as char
FROM master.sys.columns
)
, tally AS
(
SELECT ROW_NUMBER() OVER (ORDER BY column_id) N                                     -- create a tally table
FROM master.sys.columns
)
, phonenumbers AS
(
SELECT 1 ID, '000-000-0000' Phone                                                   -- some test phone numbers
UNION
SELECT 2 ID, '123-456-7890' Phone
UNION
SELECT 3 ID, '+1 (914)914-9149' Phone
UNION
SELECT 4 ID, '1111111111' Phone
)
, clean AS
(
SELECT ca.ID, ca.Number, ca.N                                                       -- remove non-number chars
FROM tally tt
CROSS APPLY (SELECT pp.ID, nn.Number, tt.N 
             FROM phonenumbers pp
             LEFT JOIN numbers nn
                ON nn.Number = SUBSTRING(pp.Phone,tt.N,1)
             WHERE tt.N <= LEN(pp.Phone)
             ) ca
WHERE ca.Number IS NOT NULL
)
SELECT cc.ID                                                                        -- put it all together
     , pp.Phone
     , (SELECT RTRIM(Number)
        FROM clean
        WHERE ID = cc.ID
        ORDER BY N
        FOR XML PATH('')) CleanPhone
     , COUNT(DISTINCT Number) CleanPhoneDistinctNumbers
     , COUNT(DISTINCT N) CleanPhoneLength
FROM clean cc
INNER JOIN phonenumbers pp
    ON cc.ID = pp.ID
GROUP BY cc.ID, pp.Phone
ORDER BY cc.ID

----------------------------------------------------------------------------------------------------

20140904 removeduplicates


There are basically 4 techniques for this task, all of them standard SQL.

NOT EXISTS

Most of the time, this is fastest in Postgres. 
SELECT ip 
FROM   login_log l 
WHERE  NOT EXISTS (
   SELECT 1             -- it is mostly irrelevant what you put here
   FROM   ip_location i
   WHERE  l.ip = i.ip
   );

Also consider:
What is easier to read in EXISTS subqueries?

LEFT JOIN / IS NULL

Sometimes this is fastest. Often shortest
SELECT l.ip 
FROM   login_log l 
LEFT   JOIN ip_location i USING (ip)  -- short for: ON i.ip = l.ip
WHERE  i.ip IS NULL;

EXCEPT

Short. Often not as fast. Not as easily integrated in more complex queries.
SELECT ip 
FROM   login_log

EXCEPT ALL              -- ALL to keep duplicate rows and make it faster
SELECT ip
FROM   ip_location;

Note that (per documentation) ...


duplicates are eliminated unless EXCEPT ALL is used.

NOT IN

Only good for small sets. I would not use it for this purpose. Performance deteriorates with bigger tables.
SELECT ip 
FROM   login_log
WHERE  ip NOT IN (
   SELECT DISTINCT ip
   FROM   ip_location
   );

NOT IN also carries a "trap" for NULL cases. Details in this related answer:

----------------------------------------------------------------------------------------------------
20141224 openxmlxquery

DECLARE @ntIdoc AS INTEGER
DECLARE @xml AS XML = '<Root>
<Emp EmpId = "1" Name = "Scott" Age = "30" Salary = "50" />
<Emp EmpId = "2" Name = "Greg" Age = "31" Salary = "50" />
<Emp EmpId = "3" Name = "Alan" Age = "34" Salary = "60" />
<Emp EmpId = "4" Name = "Alain" Age = "30" Salary = "60" />
<Emp EmpId = "5" Name = "Moti" Age = "32" Salary = "80" />
<Emp EmpId = "6" Name = "Usha" Age = "36" Salary = "80" />
<Emp EmpId = "7" Name = "Hashan" Age = "30" Salary = "80" />
</Root>'

EXEC SP_XML_PREPAREDOCUMENT @ntIdoc OUTPUT, @xml

SELECT *
FROM OPENXML (@ntIdoc, '/Root/Emp',2)
WITH (
EmpId BIGINT '@EmpId',
Name VARCHAR(200) '@Name',
Age INT '@Age',
Salary MONEY '@Salary'
)

SELECT
Emp.E.value('@EmpId', 'BIGINT') EmpId,
Emp.E.value('@Name', 'VARCHAR(200)') Name,
Emp.E.value('@Age', 'INT') Age,
Emp.E.value('@Salary', 'MONEY') Salary
FROM @xml.nodes('/Root/Emp') AS Emp(E)

----------------------------------------------------------------------------------------------------

2014112 twittersqlhelp

#sqlhelp

twitter handle vs email

----------------------------------------------------------------------------------------------------

20141024 sqlvariantproperty

DECLARE @variable1 varchar(10)
SET @variable1 = 'testtext43'


SELECT @variable1 Value
      , SQL_VARIANT_PROPERTY(@variable1, 'BaseType') BaseType
      , SQL_VARIANT_PROPERTY(@variable1, 'Precision') Precision
      , SQL_VARIANT_PROPERTY(@variable1, 'Scale') Scale
      , SQL_VARIANT_PROPERTY(@variable1, 'TotalBytes') TotalBytes
      , SQL_VARIANT_PROPERTY(@variable1, 'Collation') Collation
      , SQL_VARIANT_PROPERTY(@variable1, 'MaxLength') MaxLength
      
       
DECLARE @variable2 numeric(12,4)
SET @variable2 = '13432454.0341'


SELECT @variable2 Value
      , SQL_VARIANT_PROPERTY(@variable2, 'BaseType') BaseType
      , SQL_VARIANT_PROPERTY(@variable2, 'Precision') Precision
      , SQL_VARIANT_PROPERTY(@variable2, 'Scale') Scale
      , SQL_VARIANT_PROPERTY(@variable2, 'TotalBytes') TotalBytes
      , SQL_VARIANT_PROPERTY(@variable2, 'Collation') Collation
      , SQL_VARIANT_PROPERTY(@variable2, 'MaxLength') MaxLength

----------------------------------------------------------------------------------------------------

201410010 cleanziptallytable

SELECT q.PatXWID
      , q.ZIP
      , ca.CleanZip
FROM DAR_Members.dbo.DW_Patients_XW q
CROSS APPLY (SELECT SUBSTRING(s.ZIP,t.N,1)
                  FROM DAR_CLaims.support.tally t
                  INNER JOIN DAR_Members.dbo.DW_Patients_XW s
                        ON N BETWEEN 1 AND DATALENGTH(s.ZIP)
                        AND SUBSTRING(s.ZIP,t.N,1) LIKE '%[0-9]%'
                  WHERE s.PatXWID = q.PatXWID
                  ORDER BY t.N
                  FOR XML PATH('')) ca(CleanZip)
WHERE q.ZIP LIKE '%-%'
ORDER BY q.PatXWID

----------------------------------------------------------------------------------------------------

20141023 tallytable

here are some code examples taken from the web and from answers to this question.

For Each Method, I have modified the original code so each use the same table and column: NumbersTest and Number, with 10,000 rows or as close to that as possible. Also, I have provided links to the place of origin.

METHOD 1 here is a very slow looping method from here
avg 13.01 seconds
ran 3 times removed highest, here are times in seconds: 12.42, 13.60

DROP TABLE NumbersTest
DECLARE @RunDate datetime
SET @RunDate=GETDATE()
CREATE TABLE NumbersTest(Number INT IDENTITY(1,1)) 
SET NOCOUNT ON
WHILE COALESCE(SCOPE_IDENTITY(), 0) < 100000
BEGIN 
    INSERT dbo.NumbersTest DEFAULT VALUES 
END
SET NOCOUNT OFF
-- Add a primary key/clustered index to the numbers table
ALTER TABLE NumbersTest ADD CONSTRAINT PK_NumbersTest PRIMARY KEY CLUSTERED (Number)
PRINT CONVERT(varchar(20),datediff(ms,@RunDate,GETDATE())/1000.0)+' seconds'
SELECT COUNT(*) FROM NumbersTest
METHOD 2 here is a much faster looping one from here
avg 1.1658 seconds
ran 11 times removed highest, here are times in seconds: 1.117, 1.140, 1.203, 1.170, 1.173, 1.156, 1.203, 1.153, 1.173, 1.170

DROP TABLE NumbersTest
DECLARE @RunDate datetime
SET @RunDate=GETDATE()
CREATE TABLE NumbersTest (Number INT NOT NULL);
DECLARE @i INT;
SELECT @i = 1;
SET NOCOUNT ON
WHILE @i <= 10000
BEGIN
    INSERT INTO dbo.NumbersTest(Number) VALUES (@i);
    SELECT @i = @i + 1;
END;
SET NOCOUNT OFF
ALTER TABLE NumbersTest ADD CONSTRAINT PK_NumbersTest PRIMARY KEY CLUSTERED (Number)
PRINT CONVERT(varchar(20),datediff(ms,@RunDate,GETDATE())/1000.0)+' seconds'
SELECT COUNT(*) FROM NumbersTest
METHOD 3 Here is a single INSERT based on code from here
avg 488.6 milliseconds
ran 11 times removed highest, here are times in milliseconds: 686, 673, 623, 686,343,343,376,360,343,453

DROP TABLE NumbersTest
DECLARE @RunDate datetime
SET @RunDate=GETDATE()
CREATE TABLE NumbersTest (Number  int  not null)  
;WITH Nums(Number) AS
(SELECT 1 AS Number
 UNION ALL
 SELECT Number+1 FROM Nums where Number<10000
)
insert into NumbersTest(Number)
    select Number from Nums option(maxrecursion 10000)
ALTER TABLE NumbersTest ADD CONSTRAINT PK_NumbersTest PRIMARY KEY CLUSTERED (Number)
PRINT CONVERT(varchar(20),datediff(ms,@RunDate,GETDATE()))+' milliseconds'
SELECT COUNT(*) FROM NumbersTest
METHOD 4 here is a "semi-looping" method from here avg 348.3 milliseconds (it was hard to get good timing because of the "GO" in the middle of the code, any suggestions would be appreciated)
ran 11 times removed highest, here are times in milliseconds: 356, 360, 283, 346, 360, 376, 326, 373, 330, 373

DROP TABLE NumbersTest
DROP TABLE #RunDate
CREATE TABLE #RunDate (RunDate datetime)
INSERT INTO #RunDate VALUES(GETDATE())
CREATE TABLE NumbersTest (Number int NOT NULL);
INSERT NumbersTest values (1);
GO --required
INSERT NumbersTest SELECT Number + (SELECT COUNT(*) FROM NumbersTest) FROM NumbersTest
GO 14 --will create 16384 total rows
ALTER TABLE NumbersTest ADD CONSTRAINT PK_NumbersTest PRIMARY KEY CLUSTERED (Number)
SELECT CONVERT(varchar(20),datediff(ms,RunDate,GETDATE()))+' milliseconds' FROM #RunDate
SELECT COUNT(*) FROM NumbersTest
METHOD 5 here is a single INSERT from Philip Kelley's answer
avg 92.7 milliseconds
ran 11 times removed highest, here are times in milliseconds: 80, 96, 96, 93, 110, 110, 80, 76, 93, 93

DROP TABLE NumbersTest
DECLARE @RunDate datetime
SET @RunDate=GETDATE()
CREATE TABLE NumbersTest (Number  int  not null)  
;WITH
  Pass0 as (select 1 as C union all select 1), --2 rows
  Pass1 as (select 1 as C from Pass0 as A, Pass0 as B),--4 rows
  Pass2 as (select 1 as C from Pass1 as A, Pass1 as B),--16 rows
  Pass3 as (select 1 as C from Pass2 as A, Pass2 as B),--256 rows
  Pass4 as (select 1 as C from Pass3 as A, Pass3 as B),--65536 rows
  --I removed Pass5, since I'm only populating the Numbers table to 10,000
  Tally as (select row_number() over(order by C) as Number from Pass4)
INSERT NumbersTest
        (Number)
    SELECT Number
        FROM Tally
        WHERE Number <= 10000
ALTER TABLE NumbersTest ADD CONSTRAINT PK_NumbersTest PRIMARY KEY CLUSTERED (Number)
PRINT CONVERT(varchar(20),datediff(ms,@RunDate,GETDATE()))+' milliseconds'
SELECT COUNT(*) FROM NumbersTest
METHOD 6 here is a single INSERT from Mladen Prajdic answer
avg 82.3 milliseconds
ran 11 times removed highest, here are times in milliseconds: 80, 80, 93, 76, 93, 63, 93, 76, 93, 76

DROP TABLE NumbersTest
DECLARE @RunDate datetime
SET @RunDate=GETDATE()
CREATE TABLE NumbersTest (Number  int  not null)  
INSERT INTO NumbersTest(Number)
SELECT TOP 10000 row_number() over(order by t1.number) as N
FROM master..spt_values t1 
    CROSS JOIN master..spt_values t2
ALTER TABLE NumbersTest ADD CONSTRAINT PK_NumbersTest PRIMARY KEY CLUSTERED (Number);
PRINT CONVERT(varchar(20),datediff(ms,@RunDate,GETDATE()))+' milliseconds'
SELECT COUNT(*) FROM NumbersTest
METHOD 7 here is a single INSERT based on the code from here
avg 56.3 milliseconds
ran 11 times removed highest, here are times in milliseconds: 63, 50, 63, 46, 60, 63, 63, 46, 63, 46

DROP TABLE NumbersTest
DECLARE @RunDate datetime
SET @RunDate=GETDATE()
SELECT TOP 10000 IDENTITY(int,1,1) AS Number
    INTO NumbersTest
    FROM sys.objects s1
    CROSS JOIN sys.objects s2
ALTER TABLE NumbersTest ADD CONSTRAINT PK_NumbersTest PRIMARY KEY CLUSTERED (Number)
PRINT CONVERT(varchar(20),datediff(ms,@RunDate,GETDATE()))+' milliseconds'
SELECT COUNT(*) FROM NumbersTest
After looking at all these methods, I really like Method 7, which was the fastest and the code is fairly simple too.

----------------------------------------------------------------------------------------------------

20141001 temptabletablevariable

create table #temp (id int, value int, field varchar(10))

insert into #temp(id, value, field) VALUES (1,1,'f1'),(1,2,'f1'),(1,3,'f2')

SELECT ID, pvt1.[F1],pvt1.[F2], pvt2.[F1], pvt2.[F2]
FROM (
select id, value, field
from #temp
	) source
PIVOT
	(MAX(value) FOR Field IN ([f1],[f2])) pvt1
PIVOT
	(MIN(value) FOR Field IN ([F1],[F2])) pvt2
WHERE pvt1.ID = pvt2.ID

drop table #temp


DECLARE @tmp table (ID varchar(2))
INSERT INTO @tmp(ID) VALUES('1'),('10'),('2'),('9')

SELECT * FROM @tmp
ORDER BY ID DESC

----------------------------------------------------------------------------------------------------

