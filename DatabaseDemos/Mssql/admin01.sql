
---------------------------------------------------------------------------------
--bulk insert openrowset
bulk insert Demo.dbo.SalesArchive
from 'c:\temp\src.txt'

insert Demo.dbo.SalesArchive
select * from openrowset(
	bulk 'c:\temp\src.txt'
	,formatfile = 'c:\temp\format.xml'
)
---------------------------------------------------------------------------------------------------
--Partition Table
--Create partition function to hold range of data per filegroup
create partition function pf5KRange(int)
	as range left for values (50000);

--Create partition scheme and attach partition function along with filegroups
create partition scheme psSalesFGs
	as partition pf5KRange
	to (Data, Data2);

--Create table on Partition Scheme
create table LotsofSales (
	SaleID int primary key
	,ProductID int not null
	,Quantity smallint not null
) on psSalesFGs(SaleID)

--Create index on Parition Scheme
create nonclustered index ix_ProductID
	on LotsofSales (ProductID)
	on psSalesFGs (SaleID)
------------------------------------------------------------------------------------
--Add file to database
USE master
GO
ALTER DATABASE AdventureWorks2012
ADD FILEGROUP Test1FG1;
GO
ALTER DATABASE AdventureWorks2012 
ADD FILE 
(
    NAME = test1dat3,
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\t1dat3.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
),
(
    NAME = test1dat4,
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\t1dat4.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP Test1FG1;
GO
-------------------------------------------------------------------------------------
--create database
create database DemoDB
containment = none
on primary (
	Name = 'DemoDB'
	,FileName = 'c:\sqldata\DemoDB.mdf'
	,Size = 5MB
	,FileGrowth = 10%
)
,filegroup Data default (
	Name = 'DemoDB_data'
	,FileName = 'c:\sqldata\DemoDB_data.ndf'
	,Size = 5MB
	,FileGrowth = 10%
)
,(
	Name = 'DemoDB_data2'
	,FileName = 'c:\sqldata\DemoDB_data2.ndf'
	,Size = 5MB
	,FileGrowth = 10%
)
,filegroup Indexes (
	Name = 'DemoDB_index'
	,FileName = 'c:\sqlindexes\DemoDB_index.ndf'
	,Size = 5MB
	,FileGrowth = 10%
)
log on (
	Name = 'DemoDB_log'
	,FileName = 'c:\sqllogs\DemoDB_log.ldf'
)
-------------------------------------------------------------------------------------
You can use VALUES to create objects on the fly, see examples below. Maybe this will come in handy one day.

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
FROM (VALUES (@FileName)) a(FileName)                             -- use VALUES to create a table on the fly, this is NOT limited to one column
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
------------------------------------------------------------------------------
--20150825 powershell combine
[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.SMO")
$SObject = new-object Microsoft.SqlServer.Management.Smo.ScriptingOptions

$SObject

if (test-path 'c:\temp\tablescript.sql') {
	remove-item 'c:\temp\tablescript.sql'
}

cd sqlserver:\sql\e6cmo24\eval\databases\dbzoo\tables

gci  | % {$_.script($SObject) | out-file c:\temp\tablescript.sql -append}

cd c:\temp

$i = 1; $ct = (gci tablescript.sql).count; gci tablescript.sql | % {(get-content $_) | % {$_ -replace 'SET ANSI_NULLS ON', ''} | set-content $_; "$i of $ct"}
$i = 1; $ct = (gci tablescript.sql).count; gci tablescript.sql | % {(get-content $_) | % {$_ -replace 'SET QUOTED_IDENTIFIER ON', ''} | set-content $_; "$i of $ct"}

cd sqlserver:\sql\e6cmo24\eval\databases\dbsea\tables

invoke-sqlcmd -inputfile 'c:\temp\tablescript.sql'
-----------------------------------------------------------------------------------------------------
--20150820 powershell replace file contents
PS C:\temp> $i = 1; $ct = (gci test*.txt).count; gci test*.txt | % {(get-content $_) | % {$_ -replace 'jedi', 'knight'}
| set-content $_; '$i of $ct'}
-----------------------------------------------------------------------------------------------------
--20150820 microsoft ergonomic keyboard remap scroll zoom
Find what: <C319 .* />
Replace with: <C319 Type=”6? Activator=”ScrollUp” />

Find what: <C320 .* />
Replace with: <C320 Type=”6? Activator=”ScrollDown” />
-----------------------------------------------------------------------------------------------------
--20150820 powershell sql server snapin
Sorry, got busy over here and the forum software doesn't email me when there are new posts.

Y, I didn't get a chance to get into this the other day but here's what you have to do... since sql is just another provider in PS, you have to add it in by hand.

so when you start the PS window type these 2 commands:

add-pssnapin sqlserverprovidersnapin100
add-pssnapin sqlservercmdletsnapin100

Unfortunately, you'll have to do that every time you startup PS unless you put it in your profile. Then it will automatically load every time for you. You can put any other PS commands in there too.

To make a profile:

1. Create a folder called 'WindowsPowershell' in your documents folder.
2. Create a file called profile.ps1 in the folder you just created.
3. Type both of those commands into that file and you're good to go.

Now open a new PS window and run psdrive again and you should see your sqlserver provider there.'

set-executionpolicy remotesigned
import-module sqlps
--------------------------------------------------------------------------------------------
--20150622 run ssrs job
EXEC msdb.dbo.sp_start_job '53A153F5-0C40-469A-988D-0C12245E38ED'
--------------------------------------------------------------------------------------------
--20150619 transaction locks
SELECT * FROM sys.dm_os_wait_stats
EXEC sp_who2
----------------------------------------------------------------------------------------------------
20150120 BIML

<Biml xmlns="http://schemas.varigence.com/biml.xsd">
  <Packages>
    <Package Name="BimlPackageConfigurations" ConstraintMode="Linear">
      <PackageConfigurations>
        <PackageConfiguration Name="Configuration">
          <ExternalFileInput ExternalFilePath="C:\SSIS\Configuration.dtsConfig" />
        </PackageConfiguration>
      </PackageConfigurations>
    </Package>
  </Packages>
 
  <!-- Added: Connections -->
<Connections>
  <OleDbConnection Name="Configurations" 
    ConnectionString=
  			"Data Source=.\SQL2012;Initial Catalog=Configurations;
  								Provider=SQLNCLI10.1;Integrated Security=SSPI;Auto Translate=False;" />
</Connections>


<Connections >
    <Connection Name ="OLE_BIML"
       ConnectionString=
       	"Data Source=.;Initial Catalog=BIML;
                   Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;"/>
</Connections>

<Connections>
        <!-- Creates a connection to the Adventure Works database -->
	  <Connection Name="AdventureWorks"
	      ConnectionString=
	      					"Provider=SQLNCLI10.1;Data Source=Localhost;
	      					Persist Security Info=False;Integrated Security=SSPI;Initial Catalog=AdventureWorksDW"
	      />
</Connections>

        <PackageConfiguration Name="BimlSource" ConnectionName="Configurations">
          <ExternalTableInput Table="[dbo].[SSIS Configurations]" />
        </PackageConfiguration>
        <PackageConfiguration Name="BimlDestination" ConnectionName="Configurations">
          <ExternalTableInput Table="[dbo].[SSIS Configurations]" />
        </PackageConfiguration>
        
<Dataflow Name="Copy Data <#=table.Name#>">
    <Transformations>
        <OleDbSource Name="Retrieve Data" ConnectionName="Source">
            <DirectInput>SELECT * FROM <#=table.Name#></DirectInput>
        </OleDbSource>
        <OleDbDestination Name="Insert Data" ConnectionName="Target" KeepIdentity="true">
            <ExternalTableOutput Table="<#=table.Name#>"/>
        </OleDbDestination>
    </Transformations>
</Dataflow>
----------------------------------------------------------------------------------------
--20150211
SELECT [name] AS SSISPackageName
, CONVERT(XML, CONVERT(VARBINARY(MAX), packagedata)) AS SSISPackageXML
FROM msdb.dbo.sysdtspackages
WHERE CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(MAX), packagedata)) LIKE '%MemberMart_Update%'
----------------------------------------------------------------------------------------
--20140917 transactions

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
-------------------------------------------------------------------------------
--20140924 output parameter stored procedure

declare @rowCount int
exec yourStoredProcedureName @outputparameterspOf = @rowCount output
---------------------------------------------------------------------------------
--2014112 twittersqlhelp
#sqlhelp
twitter handle vs email
----------------------------------------------------------------------------------
--2015104 stored procedures
select * from sys.procedures
select * from sys.sql_modules
----------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------------
--20150704 dbcc database console commands
use adventure12

--View tranaction log size info
DBCC sqlperf(logspace)	

--View query stats for table or indexed view
DBCC show_statistics('SalesLT.Customer', 'IX_Customer_EmailAddress')	

--View current connections user set options
DBCC useroptions	

--Rebuilds indexes on a table
DBCC dbreindex('SalesLT.Customer')	

--Reclaims unused space from tables after variable length column dropped
DBCC cleantable(Advenure12, 'SalesLT.Customer')

-- Clean log history
EXEC dbo.sp_purge_jobhistory
    @job_name = N'NightlyBackups' ;

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
-----------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------
--20151024
USE master;

create database addw12
on (filename = 'C:\Program Files\Microsoft SQL Server\Data\AdventureWorksDW2012_Data.mdf')
for attach;

alter database addw12
set single_user;
GO

exec sp_detach_db 'addw12', 'true';
-----------------------------------------------------------------------------------
select * from sys.filegroups

--------------------------------------------------------------------
--20151024
USE master;

create database addw12
on (filename = 'C:\Program Files\Microsoft SQL Server\Data\AdventureWorksDW2012_Data.mdf')
for attach;

alter database addw12
set single_user;
GO

exec sp_detach_db 'addw12', 'true';
exec sp_help 'sp_detach_db'
exec sp_helptext 'sp_detach_db'

create database DemoDB
containment = none
on primary (
	Name = 'DemoDB'
	,FileName = 'C:\Program Files\Microsoft SQL Server\Data\DemoDB.mdf'
	,Size = 5MB
	,FileGrowth = 10%
)
,filegroup Data default (
	Name = 'DemoDB_data'
	,FileName = 'C:\Program Files\Microsoft SQL Server\Data\DemoDB.ndf'
	,Size = 5MB
	,FileGrowth = 10%
)
,filegroup Indexes (
	Name = 'DemoDB_index'
	,FileName = 'C:\Program Files\Microsoft SQL Server\Data\DemoDB_index.ndf'
	,Size = 5MB
	,FileGrowth = 10%
)
log on (
	Name = 'DemoDB_log'
	,FileName = 'C:\Program Files\Microsoft SQL Server\Data\DemoDB_log.ldf'
)
--------------------------------------------------------------------
create table dbo.dimDate (
	DateKey date not null
	,DayNumberOfWeek tinyint not null
	,DayNumberOfMonth tinyint null
	,DayNumberOfYear smallint null
	,WeekNumberOfYear tinyint null
	,CalendarQuarter smallint null
	,EnglishMonthName varchar(15) null,
	
	constraint pk_dimDate primary key(DateKey)
);

create table dbo.dimCustomer (
	CustomerKey int not null
	,Title varchar(8) null
	,Name varchar(100) null
	,BirthDate date null
	,Age as
		case
			when datediff(yy, BirthDate, current_timestamp) <= 40 then 'Younger'
			when datediff(yy, BirthDate, current_timestamp) > 50 then 'Older'
			else 'Middle Age'
		end
	,Gender char(1) null
	,AnnualIncome decimal(18,4) null

	constraint pk_dimCustomers primary key(CustomerKey)
);

create table dbo.dimProduct (
	ProductKey int not null
	,ProductNameEnglish varchar(50) not null
	,Color varchar(20) not null
	,ListPrice decimal(18,4) null
	,StandardCost decimal(18,4) null
	,DaysToManufacture int null
	,Wt decimal(18,4) null
	,ReOrderPoint smallint null

	constraint pk_dimProducts primary key(ProductKey)
);
create table dbo.FactInternetSales (
	InternetSalesKey int not null identity(1,1)
	,ProductKey int not null
	,CustomerKey int not null
	,SalesOrderNumber varchar(20) not null
	,SalesOrderLineNumber tinyint not null
	,OrderQuantity smallint not null
	,UnitPrice decimal(18,4) not null
	,ExtendedAmount decimal(18,4) not null
	,TaxAmt decimal(18,4) not null
	,OrderDate date not null

	,constraint pk_FactInternetSales primary key(InternetSalesKey)
);

create schema files authorization dbo
create schema dtsx authorization dbo

create table files.FilePath (
	FilePathID int not null identity(1,1)
	,ProjectName varchar(255) null
	,FilePath varchar(255) null
	,FilePathType varchar(100) null
) on data
alter database DemoDB
add file (
	Name = 'DemoDB_data2'
	,FileName = 'C:\Program Files\Microsoft SQL Server\Data\DemoDB_data2.ndf'
	,Size = 5MB
	,FileGrowth = 10%
)
to filegroup Data

alter database DemoDB
add filegroup Archive;
go
alter database DemoDB
add file (
	Name = 'DemoDB_archive'
	,FileName = 'C:\Program Files\Microsoft SQL Server\Data\DemoDB_archive.ndf'
	,Size = 5MB
	,FileGrowth = 10%	
) to filegroup Archive;

alter database demodb modify filegroup data default

use demodb 

create table dtsx.Library (
	BookID int not null identity(1,1)
	,Title varchar(255)
	,Author varchar(255)
	,Summary varchar(255)
) on data

create table files.FilesLoaded (
	FileID int not null identity(1,1)
	,FileNameLoaded varchar(255)
	,ProjectName varchar(255)
)

alter table dtsx.Library
add DateLoaded date not null constraint df_DateLoaded default cast(getdate() as date)

alter table dtsx.Library
add TimeLoaded time not null constraint df_TimeLoaded default cast(getdate() as time)

use demodb

--Create partition function to hold range of data per filegroup
create partition function pf5KRange(int)
	as range left for values (50000);

--Create partition scheme and attach partition function along with filegroups
create partition scheme psSalesFGs
	as partition pf5KRange
	to (Data, Data2);

--Create table on Partition Scheme
create table LotsofSales (
	SaleID int primary key
	,ProductID int not null
	,Quantity smallint not null
) on psSalesFGs(SaleID)

--Create index on Parition Scheme
create nonclustered index ix_ProductID
	on LotsofSales (ProductID)
	on psSalesFGs (SaleID)
--------------------------------------------------------------------------------

-- batch insert into existing table
set nocount on
while 1 = 1
begin
	delete top(10)
	from etl.NameColor
	where Name between 'aa' and 'll'
end

declare @BatchSize int = 10000

while 1 = 1
begin

	insert etl.NameColor --with(tablock) in 2008 for minimal logging
	(
		Name
		,Color
	)
	select top(@BatchSize)
		ss.id
		,ss.Name
		,ss.Color
	from etl.NameColor as ss
	--where id between 1 and 100000 --also multi threaded batch like this
	where not exists (
		select *
		from etl.NameColorArchive as aa --need ts in archive since duplicate id
		where aa.id = ss.id --need non clustered index on both table(id)
	)
	if @@rowcount < @BatchSize break

end
--------------------------------------------------------------------------------
-- try catch throw

declare @error_msg varchar(4000)
	,@error_severity smallint
	,@error_state smallint;

begin try
	select 1/0;
end try
begin catch
	throw;
	--select @error_msg = error_message()
	--	,@error_severity = ERROR_SEVERITY()
	--	,@error_state = error_state();
	--raiserror(@error_msg, @error_severity, @error_state);
end catch
--------------------------------------------------------------------------------
