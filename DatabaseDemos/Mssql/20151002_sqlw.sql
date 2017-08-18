

----------------------------------------------------------------------------------------------------
--20151001 xml
select xml_data.query('./Transmission/Header')
from prod.UAS_MLTC_FileData
where fileid = 6;

select xml_data.value('(./Transmission/Header/OrgId)[1]','varchar(100)')
from prod.UAS_MLTC_FileData
where fileid = 6;

select xml_data.query('./Transmission/Header/OrgId/text()')
from prod.UAS_MLTC_FileData
where fileid in (5,6);


SELECT xml_data.value('(./Transmission/Header/OrgId)[1]','varchar(100)')
from (
	values(@xml)
) as tab(xml_data);

SELECT xml_data.exist('./Transmission/Header[OrgId="03594052"]')
from (
	values(@xml)
) as tab(xml_data);

select xml_data.query('./Transmission/Header')
from prod.UAS_MLTC_FileData
where fileid = 6
	and xml_data.exist('./Transmission/Header[OrgId="03594052"]') = 1

select col.query('./text()')
from @xml.nodes('./Transmission/Content/Case/FirstName') as tab(col)


declare @xml xml;

select @xml = xml_data
from prod.UAS_MLTC_FileData
where fileid = 6;

select col.query('local-name(.)')
from @xml.nodes('(./Transmission/Content/Case/Assessment/CommunityHealth)[1]/*') as tab(col)

select 
	col.query('local-name(.)') as measure
	,col.query('local-name(..)') as source
	--col.query('.')
--into support.UAS_MLTC_Source
from prod.UAS_MLTC_FileData
cross apply XML_Data.nodes('(./Transmission/Content/Case)[1]//*') as tab(col)
where fileid in (6);

----------------------------------------------------------------------------------------------------
--lead lag 20151001
select lead(empid,2,'999') over(order by empname), empid
from dbo.employees

----------------------------------------------------------------------------------------------------
--import xml
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
EXEC sp_configure 'ad hoc distributed queries', 1
RECONFIGURE
GO
EXEC sp_configure 'show advanced options', 0
RECONFIGURE
GO

/* create temp table to store the XML data */
IF (SELECT Object_Id('tempdb..#XML_Data')) IS NULL
	BEGIN
		CREATE TABLE #XML_Data (RowID INT IDENTITY(1,1), XML_Data_Column XML, ts datetime default getdate());
	END
ELSE
	BEGIN
		TRUNCATE TABLE #XML_Data;
	END;
 
/* load a locally saved XML file to a temp table */ 
BEGIN TRY
	/* use OPENROWSET and open file as a BLOB */
	INSERT INTO #XML_Data(XML_Data_Column)
	SELECT CONVERT(XML, BulkColumn) AS BulkColumn
	FROM OPENROWSET(BULK 'C:\SQL\Collection.xml', SINGLE_BLOB) AS x;
 
	SELECT *
	FROM #XML_Data
END TRY
 
BEGIN CATCH
	/* display error message */
	SELECT ERROR_NUMBER() ErrorCode
		 , ERROR_MESSAGE() ErrorMsg;	
END CATCH

EXEC sp_configure 'show advanced options', 1
RECONFIGURE 
GO
EXEC sp_configure 'Ole Automation Procedures', 1
RECONFIGURE
GO
EXEC sp_configure 'show advanced options', 0
RECONFIGURE 
GO

/* declare variables needed during the method call */
DECLARE @URL VARCHAR(8000), @Obj int, @HTTPStatus int, @i int;
 
/* create temp table to temporarily store the xml response */
IF (SELECT Object_Id('tempdb..#XML_Responses')) IS NULL
	BEGIN
		CREATE TABLE #XML_Responses (RowID INT IDENTITY(1,1), XML_Data XML, HTTPStatus int, ts datetime default getdate());
	END
ELSE
	BEGIN
		TRUNCATE TABLE #XML_Responses;
	END;
 
/* the call might have to be repeaded since the first time the website usually responds with a message stating it accepts the request, the second call renders the XML */
BEGIN TRY
	WHILE ISNULL(@HTTPStatus,0) <> 200
		BEGIN
			/* URL used to get the boardgame list from boardgamegeek.com for Thomas Schutte */
			SELECT @URL = 'http://www.boardgamegeek.com/xmlapi2/collection?username=thrond&own=1&played=1'
 
			EXEC sp_OACreate 'MSXML2.XMLHttp', @Obj OUT 
			EXEC sp_OAMethod @Obj, 'open', NULL, 'GET', @URL, false
			EXEC sp_OAMethod @Obj, 'setRequestHeader', NULL, 'Content-Type', 'application/x-www-form-urlencoded'
			EXEC sp_OAMethod @Obj, send, NULL, ''
			EXEC sp_OAGetProperty @Obj, 'status', @HTTPStatus OUT
 
			/* store the result to our temp table */
			INSERT INTO #XML_Responses(XML_Data)
			EXEC sp_OAGetProperty @Obj, 'responseXML.xml';
			
			/* retrieve identity */
			SET @i = @@IDENTITY;
 
			/* update HTTPStatus to our table */
			UPDATE #XML_Responses
			SET HTTPStatus = @HTTPStatus
			WHERE RowID = @i
 
			/* wait for retry */
			IF @HTTPStatus <> 200
				BEGIN
					WAITFOR DELAY '00:00:02'
				END
		END;
 
	/* output all responses */
	SELECT *
	FROM #XML_Responses
 
END TRY
 
BEGIN CATCH
	SELECT ERROR_NUMBER() ErrorCode
		 , ERROR_MESSAGE() ErrorMsg;	
END CATCH
----------------------------------------------------------------------------------------------------
--Compare previous and next rows
USE AdventureWorks2012
GO
SET STATISTICS IO ON;

Query 1 for SQL Server 2012 and later version

SELECT
LAG(p.FirstName) OVER (ORDER BY p.BusinessEntityID) PreviousValue,
p.FirstName,
LEAD(p.FirstName) OVER (ORDER BY p.BusinessEntityID) NextValue
FROM Person.Person p
GO

Query 2 for SQL Server 2005+ and later version

WITH CTE AS (
SELECT
rownum = ROW_NUMBER() OVER (ORDER BY p.BusinessEntityID),
p.FirstName
FROM Person.Person p
)
SELECT
prev.FirstName PreviousValue,
CTE.FirstName,
nex.FirstName NextValue
FROM CTE
LEFT JOIN CTE prev ON prev.rownum = CTE.rownum - 1
LEFT JOIN CTE nex ON nex.rownum = CTE.rownum + 1
GO

Query 3 for SQL Server 2005+ and later version

CREATE TABLE #TempTable (rownum INT, FirstName VARCHAR(256));
INSERT INTO #TempTable (rownum, FirstName)
SELECT
rownum = ROW_NUMBER() OVER (ORDER BY p.BusinessEntityID),
p.FirstName
FROM Person.Person p;
SELECT
prev.FirstName PreviousValue,
TT.FirstName,
nex.FirstName NextValue
FROM #TempTable TT
LEFT JOIN #TempTable prev ON prev.rownum = TT.rownum - 1
LEFT JOIN #TempTable nex ON nex.rownum = TT.rownum + 1;
GO

Query 4 for SQL Server 2000+ and later version

SELECT
rownum = IDENTITY(INT, 1,1),
p.FirstName
INTO #TempTable
FROM Person.Person p
ORDER BY p.BusinessEntityID;
SELECT
prev.FirstName PreviousValue,
TT.FirstName,
nex.FirstName NextValue
FROM #TempTable TT
LEFT JOIN #TempTable prev ON prev.rownum = TT.rownum - 1
LEFT JOIN #TempTable nex ON nex.rownum = TT.rownum + 1;
GO
----------------------------------------------------------------------------------------------------

;WITH q (n) AS (
   SELECT 1
   UNION ALL
   SELECT n + 1
   FROM   q
   WHERE  n < 10000
)
INSERT INTO table1 
SELECT * FROM q
OR

DECLARE @batch   INT,
@rowcounter INT,
@maxrowcount    INT

SET @batch   = 10000
SET @rowcounter = 1

SELECT @maxrowcount = max(id) FROM table1 

WHILE @rowcounter <= @maxrowcount
BEGIN   
INSERT INTO table2 (col1)
SELECT col1
FROM table1
WHERE 1 = 1
AND id between @rowcounter and (@rowcounter + @batch)
---------------------------------------------------------------------------------------------------
-- Set the @rowcounter to the next batch start
SET @rowcounter = @rowcounter + @batch + 1;
END

bulk insert Demo.dbo.SalesArchive
from 'c:\temp\src.txt'

insert Demo.dbo.SalesArchive
select * from openrowset(
	bulk 'c:\temp\src.txt'
	,formatfile = 'c:\temp\format.xml'
)
---------------------------------------------------------------------------------------------------
dbcc sqlperf(logspace)
dbcc show_statistics('sales.salesorderdetail', 'ix_salesorderdetail_productid')
dbcc help('checkdb')
dbcc useroptions

---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------------
--20150910 extended properties trigger
select * from sys.extended_properties

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


SELECT QUOTENAME(DB_NAME()) + ISNULL('.' + QUOTENAME(OBJECT_SCHEMA_NAME(pp.major_id)) + '.' + QUOTENAME(OBJECT_NAME(pp.major_id)),'') ObjectName
	 , CAST(LEFT(pp.name,22) AS DATETIME) ChangeDate
	 , SUBSTRING(pp.name, 27, CHARINDEX('(', pp.name) - 28) ChangeType
	 , UPPER(REPLACE(STUFF(pp.name, 1, CHARINDEX('(', pp.name),''),')','')) ChangeUser
	 , pp.value Code	 
FROM sys.extended_properties pp
WHERE ISDATE(LEFT(pp.name,22)) = 1
ORDER BY ObjectName, ChangeDate

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
---------------------------------------------------------------------------------------------------
--20150910 xml openxml
/* declare variable with XML datatype */ 
DECLARE @XML XML
	,@IDoc int; 
 
/* assign sample XML to variable */ 
SET @XML = '<?xml version="1.0" encoding="UTF-8" standalone="no" ?> 
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
			</items>'; 

exec sp_xml_preparedocument @IDoc Output, @XML

select 
	id
	,name
	,comment
from openxml (@IDoc, '/items/item')
with (
	id			int				'./@id'
	,name		varchar(200)	'./name/text()'
	,comment	varchar(200)	'./comment'
)

exec sp_xml_removedocument @IDOC

---------------------------------------------------------------------------------------------------
--20150903
declare @sql varchar(max) = space(0)

select @sql = @sql + char(13) + char(10) + ',' + column_name
from INFORMATION_SCHEMA.columns
where table_name = 'HF_MHMO_MLTC_CLAIMS'
and column_name like '%date%'

if len(@sql) > 0
begin
	set @sql = stuff(@sql, 1, 3, '')
end

select @sql = 
	'select ' + char(13) + char(10)
	+ @sql + char(13) + char(10)
	+ 'from raw.HF_MHMO_MLTC_CLAIMS'

select cast(@sql as xml)

/*
	5/28/2015: Ed Pollack
	ed7@alum.rpi.edu
	
	Dynamic SQL: Writing Efficient Queries on the Fly

	This SQL demonstrates a number of ways in which dynamic SQL can be effectively written to
	improve SQL Server performance, to automate difficult tasks, or allow complex queries to be run
	in stored procs when unknowns exist at run-time.
*/
USE AdventureWorks
GO
SET STATISTICS IO ON
SET NOCOUNT ON

/*****************************************************************************************************************
********************************************Dynamic SQL Basics****************************************************
******************************************************************************************************************/

DECLARE @CMD VARCHAR(MAX)
SET @CMD = 'SELECT TOP 10 * FROM Person.Person'
PRINT @CMD
EXEC @CMD -- Always put the command in parenthesis!  Treat EXEC / EXECUTE like a function as it requires the string as a parameter.
GO

DECLARE @CMD VARCHAR(MAX)
SET @CMD = 'SELECT TOP 10 * FROM Person.Person'
PRINT @CMD
EXEC (@CMD) -- Always put the command in parenthesis!
GO

DECLARE @CMD VARCHAR(MAX)
DECLARE @table VARCHAR(100)
SET @table = 'Person.Person'
SET @CMD = 'SELECT TOP 10 * FROM ' + @table -- Dynamic table search
PRINT @CMD
EXEC (@CMD)
GO
/*****************************************************************************************************************
****************************************Good Dynamic SQL Style****************************************************
******************************************************************************************************************/

DECLARE @CMD VARCHAR(MAX) = '' -- This will hold the final SQL to execute
DECLARE @first_name VARCHAR(50) = 'Edward' -- First name as entered in search box
DECLARE @phone_number_type VARCHAR(10) = 'Cell' -- Phone number type as entered in drop-down.  Optional.
SET @CMD = 
'
SELECT
	PERSON.FirstName,
	PERSON.LastName,
	PHONE.PhoneNumber,
	PTYPE.Name
FROM Person.Person PERSON
INNER JOIN Person.PersonPhone PHONE
ON PERSON.BusinessEntityID = PHONE.BusinessEntityID
INNER JOIN Person.PhoneNumberType PTYPE
ON PHONE.PhoneNumberTypeID = PTYPE.PhoneNumberTypeID
WHERE PERSON.FirstName = ''' + @first_name + '''
'
IF @phone_number_type IS NOT NULL -- Only check phone # type if value is supplied!
BEGIN
	SET @CMD = @CMD +
	'
	AND PTYPE.Name = ''' + @phone_number_type + '''
	'
END	
PRINT @CMD -- Debug!
EXEC (@CMD)
GO

-- Beware mistakes in the text portion that will compile normally, but error at runtime:
DECLARE @CMD VARCHAR(MAX)
SET @CMD = 'SELLECT TOP 17 * FROM Person.Person'
PRINT @CMD
EXEC (@CMD)

/*****************************************************************************************************************
**********************Efficiently Generating Lists From Table Data************************************************
******************************************************************************************************************/
-- This is a common cursor-based iterative approach.  It's slow, inefficient, and not great for job security.
-- As always, most row-by-row solutions will be problematic and should be avoided unless abolutely necessary.
-- Total subtree cost: 2.006, 1021 logical reads!
DECLARE @nextid INT
DECLARE @myIDs VARCHAR(MAX) = ''

DECLARE idcursor CURSOR FOR
SELECT TOP 100
	BusinessEntityID
FROM Person.Person
ORDER BY LastName
OPEN idcursor
FETCH NEXT FROM idcursor INTO @nextid

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @myIDs = @myIDs + CAST(@nextid AS VARCHAR(5)) + ','
	FETCH NEXT FROM idcursor INTO @nextid
END
SET @myIDs = LEFT(@myIDs, LEN(@myIDs) - 1)
CLOSE idcursor
DEALLOCATE idcursor

SELECT @myIDs
GO
-- This is an old school approach from when XML first came to SQL Server.  The execution plan shows that while
-- this method reduces the number of operations & reads greatly, the XML usage itself is extremely inefficient.
-- Total subtree cost: 1.08051, 3 logical reads (far less reads, but still heavier on processing)
DECLARE @myIDs VARCHAR(MAX) = ''

SET @myIDs = STUFF((SELECT TOP 100 ',' + CAST(BusinessEntityID AS VARCHAR(5))
FROM Person.Person
ORDER BY LastName
FOR XML PATH(''), TYPE
).value('.', 'VARCHAR(MAX)'), 1, 1, '')

SELECT @myIDs
GO
-- This method uses dynamic SQL to quickly generate a list in a single statement.  The only CPU/disk
-- consumption is that needed to retrieve the data from the base table.  The remainder of the operations
-- use negligible disk/CPU/memory and are VERY fast.
-- Total subtree cost: 0.0038369, 3 logical reads (far less reads AND far less processing!)
DECLARE @myIDs VARCHAR(MAX) = ''
SELECT TOP 100 @myIDs = @myIDs + CAST(BusinessEntityID AS VARCHAR(5)) + ','
FROM Person.Person
ORDER BY LastName
SET @myIDs = LEFT(@myIDs, LEN(@myIDs) - 1)

SELECT @myIDs

-- Lists can be created from multiple columns as well:
DECLARE @myData VARCHAR(MAX) = ''
SELECT @myData = 
	@myData + CAST(ContactTypeID AS VARCHAR(50)) + ',' + Name + ','
FROM person.ContactType
SET @myData = LEFT(@myData, LEN(@myData) - 1)

SELECT @myData
GO
/*****************************************************************************************************************
*********************************************sp_executesql********************************************************
******************************************************************************************************************/
-- Here is our example from earlier:
DECLARE @CMD VARCHAR(MAX) = '' -- This will hold the final SQL to execute
DECLARE @first_name VARCHAR(50) = 'Edward' -- First name as entered in search box
DECLARE @phone_number_type VARCHAR(10) = 'Cell' -- Phone number type as entered in drop-down.  Optional.
SET @CMD = 
'
SELECT
	PERSON.FirstName,
	PERSON.LastName,
	PHONE.PhoneNumber,
	PTYPE.Name
FROM Person.Person PERSON
INNER JOIN Person.PersonPhone PHONE
ON PERSON.BusinessEntityID = PHONE.BusinessEntityID
INNER JOIN Person.PhoneNumberType PTYPE
ON PHONE.PhoneNumberTypeID = PTYPE.PhoneNumberTypeID
WHERE PERSON.FirstName = ''' + @first_name + '''
'
IF @phone_number_type IS NOT NULL -- Only check phone # type if value is supplied!
BEGIN
	SET @CMD = @CMD +
	'
	AND PTYPE.Name = ''' + @phone_number_type + '''
	'
END	
PRINT @CMD -- Debug!
EXEC (@CMD)
GO

-- Using dynamic SQL, it would look like this:
DECLARE @CMD NVARCHAR(MAX) = '' -- This will hold the final SQL to execute
DECLARE @my_first_name NVARCHAR(50) = 'Edward' -- First name as entered in search box
DECLARE @my_phone_number_type NVARCHAR(10) = 'Cell' -- Phone number type as entered in drop-down.  Optional.
SET @CMD = 
'
SELECT
	PERSON.FirstName,
	PERSON.LastName,
	PHONE.PhoneNumber,
	PTYPE.Name
FROM Person.Person PERSON
INNER JOIN Person.PersonPhone PHONE
ON PERSON.BusinessEntityID = PHONE.BusinessEntityID
INNER JOIN Person.PhoneNumberType PTYPE
ON PHONE.PhoneNumberTypeID = PTYPE.PhoneNumberTypeID
WHERE PERSON.FirstName = @first_name -- *** parameters no longer need to be surrounded in a sea of apostrophes ***
'
IF @my_phone_number_type IS NOT NULL -- Only check phone # type if value is supplied!
BEGIN
	SET @CMD = @CMD +
	'
	AND PTYPE.Name = @phone_number_type
	'
END

EXEC sp_executesql @CMD, N'@first_name NVARCHAR(50), @phone_number_type NVARCHAR(10)', @my_first_name, @my_phone_number_type

-- Parameter list can also be stored in a scalar variable, to improve readability
DECLARE @parameter_list NVARCHAR(MAX) = N'@first_name NVARCHAR(50), @phone_number_type NVARCHAR(10)'
EXEC sp_executesql @CMD, @parameter_list, @my_first_name, @my_phone_number_type

/*****************************************************************************************************************
******************************************Parameter Sniffing******************************************************
******************************************************************************************************************/
/*
	The first time a stored procedure or sp_executesql command is run, the query execution plan is cached.  This
	cached plan was created using the specific parameters passed in this first time.  All subsequent executions
	will use this same execution plan, regardless of the new parameters, until the plan is eventually removed
	from cache.

	This behavior is often desirable, but if bad execution plans are being created we may wish to avoid this.	
*/

USE AdventureWorks
GO

CREATE NONCLUSTERED INDEX NCI_production_product_ProductModelID ON Production.Product (ProductModelID) INCLUDE (Name)
GO

-- Create a simple stored procedure that will get all products from production.product with a specific range of model IDs
CREATE PROCEDURE get_products_by_model (@firstProductModelID INT, @lastProductModelID INT) 
AS
BEGIN
	SELECT
		PRODUCT.Name,
		PRODUCT.ProductID,
		PRODUCT.ProductModelID,
		PRODUCT.ProductNumber,
		MODEL.Name
	FROM Production.Product PRODUCT
	INNER JOIN Production.ProductModel MODEL
	ON MODEL.ProductModelID = PRODUCT.ProductModelID
	WHERE PRODUCT.ProductModelID BETWEEN @firstProductModelID AND @lastProductModelID;
END
GO

-- Clear the plan cache.  *** ONLY USE THIS DBCC COMMAND IN DEV ENVIRONMENTS WHERE PERFORMANCE IS NOT IMPORTANT! ***
DBCC FREEPROCCACHE

-- Execute the stored proc with a narrow range of model numbers
EXEC get_products_by_model 120, 125

-- Clear the plan cache
DBCC FREEPROCCACHE

-- Execute the stored procedure with a wide range of model numbers.  Note the difference in execution plan and subtree cost.
EXEC get_products_by_model 0, 10000

-- Without clearing the cache, run the same proc with the narrow range of product model IDs.  Note the reuse of the last execution plan, despite not being the optimal plan.
EXEC get_products_by_model 120, 125

DROP PROCEDURE get_products_by_model
DROP INDEX NCI_production_product_ProductModelID ON Production.Product
GO
/*****************************************************************************************************************
******************************************SQL Injection***********************************************************
******************************************************************************************************************/
-- This simulates a very simple first name search of the Person.Person table:
DECLARE @CMD VARCHAR(MAX)
DECLARE @search_criteria VARCHAR(1000) -- This comes from user input

SET @CMD = 'SELECT * FROM Person.Person
WHERE FirstName = '''
SET @search_criteria = 'Edward'
SET @CMD = @CMD + @search_criteria
SET @CMD = @CMD + ''''
PRINT @CMD
EXEC (@CMD)
GO

-- What if a user uses an apostrophe in their search terms?
DECLARE @CMD VARCHAR(MAX)
DECLARE @search_criteria VARCHAR(1000) -- This comes from user input

SET @CMD = 'SELECT * FROM Person.Person
WHERE FirstName = '''
SET @search_criteria = 'O''Brien'
SET @CMD = @CMD + @search_criteria
SET @CMD = @CMD + ''''
PRINT @CMD
EXEC (@CMD) -- This generates a syntax error as Brien' is being read as SQL after the 2nd apostrophe
GO

-- What if a malicious user wants to exploit this?
-- What if a user uses an apostrophe in their search terms?
DECLARE @CMD VARCHAR(MAX)
DECLARE @search_criteria VARCHAR(1000) -- This comes from user input

SET @CMD = 'SELECT * FROM Person.Person
WHERE FirstName = '''
SET @search_criteria = ''' SELECT * FROM Person.Password; SELECT '''
SET @CMD = @CMD + @search_criteria
SET @CMD = @CMD + ''''
PRINT @CMD
EXEC (@CMD) -- The user can do whatever they want once they terminate the quotes, assuming they have permissions
/* The SQL looks like this when executed!  It could have potentially dropped, updated, deleted, or otherwise
   brutalized our database before we had any opportunity to stop them.
SELECT * FROM Person.Person
WHERE FirstName = '' SELECT * FROM Person.Password; SELECT ''
*/

-- The solution!
CREATE PROCEDURE search_people
	 (@search_criteria NVARCHAR(1000) = NULL) -- This comes from user input
AS
BEGIN
	DECLARE @CMD NVARCHAR(MAX) -- Must be NVARCHAR, as that is how sp_executesql is built
	SET @CMD = 'SELECT * FROM Person.Person
	WHERE 1 = 1'
	IF @search_criteria IS NOT NULL
		SELECT @CMD = @CMD + '
	AND FirstName = @search_criteria'
	PRINT @CMD
	EXEC sp_executesql @CMD, N'@search_criteria NVARCHAR(1000)', @search_criteria
END
GO

-- This runs as usual:
EXEC search_people 'Edward'
-- One more example for the name with an apostrophe in it:
EXEC search_people 'O''Brien'
-- By parameterizing sp_executesql, we force this to search like any other text, even with the attempted attack:
EXEC search_people ''' SELECT * FROM Person.Password; SELECT '''

DROP PROCEDURE search_people -- Cleanup

-- Another solution is to use QUOTENAME to ensure that the input is properly cleansed on the way in:
CREATE PROCEDURE search_people
	 (@search_criteria NVARCHAR(1000) = NULL) -- This comes from user input
AS
BEGIN
	DECLARE @CMD NVARCHAR(MAX) -- Must be NVARCHAR, as that is how sp_executesql is built
	SET @CMD = 'SELECT * FROM Person.Person
	WHERE 1 = 1'
	IF @search_criteria IS NOT NULL
		SELECT @CMD = @CMD + '
	AND FirstName = ' + QUOTENAME(@search_criteria, '''')
	PRINT @CMD
	EXEC (@CMD)
END
GO

-- This runs as usual:
EXEC search_people 'Edward'
-- One more example for the name with an apostrophe in it:
EXEC search_people 'O''Brien'
-- By using QUOTENAME, we force the input text to be formatted correctly, regardless of the characters entered:
EXEC search_people ''' SELECT * FROM Person.Password; SELECT '''

DROP PROCEDURE search_people -- Cleanup
GO

/*****************************************************************************************************************
******************************Saving From Dynamic SQL Output******************************************************
******************************************************************************************************************/
-- This example shows a dynamic query being built that selects some data from a table and outputs it directly
-- into a table variable for future use.  This example is trivial, but there are instances where there may be
-- no better way to select data from dynamic SQL.
DECLARE @CMD VARCHAR(MAX)
DECLARE @output TABLE
(	PersonType NCHAR(2),
	Title NVARCHAR(8),
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	Suffix NVARCHAR(10))
DECLARE @search_term VARCHAR(50) = 'Edward'
DECLARE @promotion BIT = 1
SET @CMD = '
	SELECT
		PersonType,
		Title,
		FirstName,
		LastName,
		Suffix
	FROM Person.Person
	WHERE FirstName = ' + QUOTENAME(@search_term, '''')
IF @promotion = 0
	SET @CMD = @CMD + '
	AND EmailPromotion = 0'
ELSE
	SET @CMD = @CMD + '
	AND EmailPromotion <> 0'
PRINT @CMD
INSERT INTO @output
(	PersonType,
	Title,
	FirstName,
	LastName,
	Suffix)
EXEC (@CMD)

SELECT
	*
FROM @output
GO

/*****************************************************************************************************************
*************************************The Crazy Dynamic Pivot******************************************************
******************************************************************************************************************/
/*	By default, PIVOT requires a static list of values to be used as the column headers when we pivot row data into
	column data.  We can use dynamic SQL to allow for a flexible column header list.  The result can be extremely
	useful when data must be pivoted, but we do not know until runtime which values to pivot/aggregate on.	*/

-- Example: A query that calculates the quantity of each product by color, moving the colors to the column headers:
SELECT
	*
FROM
(	SELECT
		PRODUCT.Name AS product_name,
		PRODUCT.Color AS product_color,
		PRODUCT.ReorderPoint,
		PRODUCT_INVENTORY.Quantity AS product_quantity
	FROM Production.Product PRODUCT
    LEFT JOIN Production.ProductInventory PRODUCT_INVENTORY
    ON PRODUCT.ProductID = PRODUCT_INVENTORY.ProductID
) PRODUCT_DATA
PIVOT
(	SUM(product_quantity)
	FOR product_color IN ([Black], [Blue], [Grey], [Multi], [Red], [Silver], [Silver/Black], [White], [Yellow]  )
) PIVOT_DATA
----------------------------------------------------------------------------------------------------------------------
-- The color list MUST be provided in the PIVOT using explicit names.
-- What if we want to pass in a table of colors and ONLY generate columns for those?
----------------------------------------------------------------------------------------------------------------------
DECLARE @colors TABLE
	(color_name VARCHAR(25)	)

INSERT INTO @colors
	(color_name)
VALUES ('Black'), ('Grey'), ('Silver/Black'), ('White')

DECLARE @CMD VARCHAR(MAX)
SET @CMD = '
SELECT
	*
FROM
(	SELECT
		PRODUCT.Name AS product_name,
		PRODUCT.Color AS product_color,
		PRODUCT.ReorderPoint,
		PRODUCT_INVENTORY.Quantity AS product_quantity
	FROM Production.Product PRODUCT
    LEFT JOIN Production.ProductInventory PRODUCT_INVENTORY
    ON PRODUCT.ProductID = PRODUCT_INVENTORY.ProductID
) PRODUCT_DATA
PIVOT
(	SUM(product_quantity)
	FOR product_color IN ('

SELECT @CMD = @CMD + '[' + color_name + '], '
FROM @colors

SET @CMD = SUBSTRING(@CMD, 1, LEN(@CMD) - 1)

SET @CMD = @CMD + '	)
) PIVOT_DATA
'

PRINT @CMD
EXEC (@CMD)
GO

-- This would allow a PIVOT to evolve over time to accomodate new colors as they are added.  For example,
-- you could write a similar query to get all distinct colors in the product table and then pivot using those values.
-- This ensures that as data changes, your PIVOT will incorporate that change seamlessly, without the need
-- for manual edits to your TSQL:
DECLARE @colors TABLE
	(color_name VARCHAR(25)	)

INSERT INTO @colors
	(color_name)
SELECT DISTINCT
	Product.Color
FROM Production.Product
WHERE Product.Color IS NOT NULL

DECLARE @CMD VARCHAR(MAX)
-- Build the base SQL for the PIVOT.  This is exactly the same as before.
SET @CMD = '
SELECT
	*
FROM
(	SELECT
		PRODUCT.Name AS product_name,
		PRODUCT.Color AS product_color,
		PRODUCT.ReorderPoint,
		PRODUCT_INVENTORY.Quantity AS product_quantity
	FROM Production.Product PRODUCT
    LEFT JOIN Production.ProductInventory PRODUCT_INVENTORY
    ON PRODUCT.ProductID = PRODUCT_INVENTORY.ProductID
) PRODUCT_DATA
PIVOT
(	SUM(product_quantity)
	FOR product_color IN ('

-- Add in our list of colors from above.  Be sure to include brackets and commas to avoid syntax errors when
-- this is executed
SELECT @CMD = @CMD + '[' + color_name + '], '
FROM @colors

-- Remove that comma at the end since there are no more values to add to the list.
SET @CMD = SUBSTRING(@CMD, 1, LEN(@CMD) - 1)

SET @CMD = @CMD + '	)
) PIVOT_DATA
'

PRINT @CMD
EXEC (@CMD)

-- Final test: Let's add a few new colors to the Production.Product table and re-run our query from above:
UPDATE Production.Product
SET Product.Color = 'Fuschia'
WHERE Product.ProductID = 325 -- Decal 1
UPDATE Production.Product
SET Product.Color = 'Aquamarine'
WHERE Product.ProductID = 326 -- Decal 2

/* Cleanup:
UPDATE Production.Product
SET Product.Color = NULL
WHERE Product.ProductID = 325 -- Decal 1
UPDATE Production.Product
SET Product.Color = NULL
WHERE Product.ProductID = 326 -- Decal 2
*/
-----------------------------------------------------------------------------------------------------
--20150831 conditional join or http://weblogs.sqlteam.com/jeffs/archive/2007/04/03/Conditional-Joins.aspx
select
  E.EmployeeName, coalesce(s.store,o.office) as Location
from
  Employees E
left outer join 
  Stores S on ...
left outer join
  Offices O on ...
where
  O.Office is not null OR S.Store is not null

-----------------------------------------------------------------------------------------------------
--20150831 xml grouping sets grouping id
DECLARE @person XML
declare @i int = 1
set @person = (
	select xml_data
	from prod.UAS_MLTC_FileData
	where fileid = 6 
)

;WITH nodeData AS (
    SELECT 
        node.value('local-name(.)', 'NVARCHAR(MAX)') AS nodeName,
        node.query('.') AS nodeInstance
		,@i as lvl
    FROM @person.nodes('/*') a(node)
    UNION ALL
    SELECT 
        node.value('local-name(.)', 'NVARCHAR(MAX)'),
        node.query('.')
		,lvl + 1
    FROM nodeData
    CROSS APPLY nodeInstance.nodes('/*/*') b(node)
)
SELECT nodeName
	,COUNT(nodeName) AS nodeCount 
FROM nodeData
GROUP BY nodeName 
ORDER BY nodeName asc, nodeCount DESC


select
	case
		when grouping_id(nn.NodeName, nn.nodeCount) > 0
			then 'Total'
		else nn.nodeName
	end as nodeName
	,nn.nodeCount
	,sum(CASE
		when tt.MeasureID is null then 0
		else 1
	end) as Extracted
from stage.UAS_MLTC_NodeList as nn
left join dar_cm.prod.UAS_MLTC_Measure_Types as tt
	on nn.nodeName = tt.Measure
group by grouping sets((nn.NodeName, nn.nodeCount),())
-----------------------------------------------------------------------------------------------------
--20150831 Delete Intersection
	DELETE prod
	OUTPUT deleted.*
	INTO [DARPlanning].[dbo].[LOS_weekly_rpt_Deleted]
	FROM [DARPlanning].[prod].[LOS_weekly_rpt] as prod
	WHERE exists (
		select prod.[ED_From]
		  ,prod.[dayofwk]
		intersect 
		select [ED_From]
		  ,[dayofwk]
		from [DARPlanning].[dbo].[LOS_weekly_rpt] 
	)
-----------------------------------------------------------------------------------------------------
--20150831 Calculate Age
declare
	@dob datetime = '2014-09-01'

SELECT
	case 
		when dateadd(yy, datediff(yy, @dob, getdate()), @dob) > getdate()
			then datediff(yy, @dob, getdate()) - 1
		else datediff(yy, @dob, getdate())
	end

-----------------------------------------------------------------------------------------------------
--20150828 With Rollup
CREATE TABLE dbo.Grouping (EmpId INT, Yr INT, Sales MONEY)
INSERT dbo.Grouping VALUES(1, 2005, 12000)
INSERT dbo.Grouping VALUES(1, 2006, 18000)
INSERT dbo.Grouping VALUES(1, 2007, 25000)
INSERT dbo.Grouping VALUES(2, 2005, 15000)
INSERT dbo.Grouping VALUES(2, 2006, 6000)
INSERT dbo.Grouping VALUES(3, 2006, 20000)
INSERT dbo.Grouping VALUES(3, 2007, 24000)

select * 
from dbo.Grouping

SELECT EmpId, Yr, sum(Sales) as Sales
FROM dbo.Grouping
GROUP BY EmpId, Yr WITH ROLLUP

SELECT EmpId, Yr, sum(Sales) as Sales
FROM dbo.Grouping
GROUP BY EmpId, Yr WITH CUBE

We can rewrite these two queries using the new syntax as:

SELECT EmpId, Yr, sum(Sales) as Sales
FROM dbo.Grouping
GROUP BY ROLLUP(EmpId, Yr)

SELECT EmpId, Yr, sum(Sales) as Sales
FROM dbo.Grouping
GROUP BY CUBE(EmpId, Yr)
-----------------------------------------------------------------------------------------------------
--20150828 xml 
DECLARE @person XML
declare @i int = 1
SELECT @person = CAST('
    <person>
        <age>
            <year value="2010"/>
            <month value="10"/>
            <day value="21"/>
        </age>
        <age>
            <year value="2011"/>
            <month value="11"/>
            <day value="4"/>
        </age>
    </person>' AS XML)


;WITH nodeData AS (
    SELECT 
        node.value('local-name(.)', 'NVARCHAR(MAX)') AS nodeName,
        node.query('.') AS nodeInstance
		,@i as lvl
    FROM @person.nodes('/*') a(node)
    UNION ALL
    SELECT 
        node.value('local-name(.)', 'NVARCHAR(MAX)'),
        node.query('.')
		,lvl + 1
    FROM nodeData
    CROSS APPLY nodeInstance.nodes('/*/*') b(node)
)

SELECT nodeName, COUNT(nodeName) AS nodeCount FROM nodeData
GROUP BY nodeName 
ORDER BY nodeCount DESC

-----------------------------------------------------------------------------------------------------
	declare @filePeriod varchar(20)
		,@nameReverse varchar(50) = reverse(@fileName)

	select 
		@filePeriod = reverse(substring(aa.nameReverse, bb.position + 1, 13))
	from (
		values(@nameReverse)
	) as aa(nameReverse)
	cross apply (
		select charindex('.',aa.nameReverse)) as bb(position)

	IF EXISTS (
		SELECT * FROM raw.Load_Statistics
		WHERE File_Name = @fileName
	)
		SELECT 0 as cnt, @filePeriod as filePeriod
	ELSE
		select 1 as cnt, @filePeriod as filePeriod
-----------------------------------------------------------------------------------------------------
	declare @filename varchar(255) = '08-2015 Monte Pri-Sup Roster.xlsx'
	declare @filePeriod varchar(50)
	
	;with digits as (
		select xx.N, xx.Chr
		from raw.tally as tt
		cross apply (
			select tt.N as N
				,substring(ff.name, tt.N, 1) as Chr
			from (values(@filename)) as ff(name)
			where tt.N <= len(ff.name)
		) as xx
		left join raw.tallyChar as cc
			on xx.Chr = cc.Chr
		where patindex('%[0-9]%', xx.Chr) > 0
	)
	select cast(
		(
			select '' + Chr
			from digits
			order by N
			for xml path('')) as varchar(255)
	)
	
-----------------------------------------------------------------------------------------------------
--20150827
;with DirtyData as (
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

-----------------------------------------------------------------------------------------------------
declare @x xml
set @x = '<root>
			<row id="1"><name>Larry</name></row>
			<row id="2"><name>Moe</name></row>
			<row id="3"><name>Curly</name></row>
		</root>'

select T.c.query('.')
from @x.nodes('/root/row') as T(c)

-----------------------------------------------------------------------------------------------------
Have you seen this? 
Why is yours 45 lines long! It’s cool, I’m only a little disappointed.

declare @keepvalue varchar(100)
      ,@temp varchar(100) 
set @keepvalue = '%[^a-z]%'
set @temp = 'dihijs350klj180[\\]'

while patindex(@keepvalue, @temp) > 0
begin

      set @temp = stuff(@temp, patindex(@keepvalue, @temp), 1, space(0))

end

select @temp

-----------------------------------------------------------------------------------------------------
You can use this function to split strings (any separator as long as it’s a singe character, for example “,”, “|” or TAB). Might come in handy.

/*
SELECT *
FROM dbo.fnSplitString('HIC_NUM_MASTER    BENE_HIC_NUM      BENE_FIPS_STATE_CD      BENE_ALGNMNT_YR_3_HCC_SCRE_NUM', CHAR(9)) -- CHAR(9) = TAB

SELECT *
FROM dbo.fnSplitString('test,another test, last test', ',')
*/

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

-----------------------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------------------------
--20150827
I just stumbled across the neatest trick I’ve seen in a while. If you ever have to clean your data for dummy entries like ‘111111111’, or ‘AAAAAA’ (values that only have one repeating character) use this:

DECLARE @sampletable TABLE (Value varchar(20))
INSERT INTO @sampletable VALUES ('1111111'),('ABCDEF'),('AAAAAAA'),('DDD'),('88888888'),('12233')

SELECT *
FROM @sampletable
WHERE REPLACE(Value, LEFT(Value,1),'') = ''


-----------------------------------------------------------------------------------------------------
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

-----------------------------------------------------------------------------------------------------
--20150810 tally table parse string duplicate character
DECLARE @S VARCHAR(8000) = 'Aarrrgggh!';

;with tally(n) as (
	select row_number() over(order by (select null))
	from (
		values(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)
		) as aa(n)
		cross join (
			values(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)
		) as bb(n)
		cross join (
			values(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)
		) as cc(n)
		cross join (
			values(0),(0),(0),(0),(0),(0),(0),(0)
		) as dd(n)
)select @S as OldString
	,(
		select '' + c
			from (
					SELECT n, c
					from
					(
						select 1 as n, left(@S, 1) as c
						union ALL
						select n
							,CASE
								when substring(@S, n-1, 1) <> substring(@S, n, 1)
									then substring(@S, n, 1)
							end
						from tally
						where n between 2 and len(@s)
					) as aa
					where c is not null
				) as bb
			order by bb.n
			for xml path(''), type
	).value('.','varchar(8000)') as NewString
-----------------------------------------------------------------------------------------------------
--20150810 tally table table of dates

CREATE TABLE #Temp
(
    ID          INT IDENTITY PRIMARY KEY
    ,StartDT    DATETIME
);

INSERT INTO #Temp
SELECT '2014-02-18 09:20' UNION ALL SELECT '2014-02-19 05:35';

;with Tally (Num) as (
	select 0
	union all
	select row_Number() over(order by(select null))
	from (values(0),(0),(0),(0),(0)) as aa(num)
	cross join (values(0),(0),(0),(0),(0)) as bb(num)
)
select
	id
	,dateadd(hour, Num, dateadd(day, 0 ,datediff(day, 0, StartDt))) as Dt
from #temp
cross apply (
	select Num
	from Tally as tt
	where Num between 0 and datepart(hour, dateadd(hour, datediff(hour, 0, StartDt), 0))
) as xa(Num)
order by id, Dt

-----------------------------------------------------------------------------------------------------
--20150810 cross apply unpivot
CREATE TABLE Dates (id INT IDENTITY(1, 1),date1 DATETIME,date2 DATETIME,date3 DATETIME)
 
INSERT INTO Dates
(date1,date2,date3)
VALUES ('1/1/2012','1/2/2012','1/3/2012'),
('1/1/2012',NULL,'1/13/2012'),
('1/1/2012','1/2/2012',NULL),
('8/30/2012','9/10/2012','1/1/2013')
 
--Table Value
Select ID, MyDate, Date123
FROM Dates A
Cross Apply ( Values (Date1,'Date1'), (Date2,'Date2'), (Date3,'Date3')) B(MyDate, Date123)
 
--UNPIVOT
SELECT ID, MyDate ,date123 
FROM (
	SELECT id,date1,date2,date3 FROM Dates) src
UNPIVOT (MyDate
FOR date123 IN ([date1],[date2],[date3])) unpvt
-----------------------------------------------------------------------------------------------------
--20150810 gaps and islands
select cur + 1, nxt - 1
from (
	select aa.SeqNo as cur
		,(	select MIN(bb.SeqNo)
			from dbo.GapsIslands as bb
			where aa.SeqNo < bb.SeqNo
		) as nxt
	from dbo.GapsIslands as aa
) as cc
where nxt - cur > 1


select  seqNo + 1 as startGap
	,(
		select min(seqNo)
		from dbo.GapsIslands as bb
		where bb.seqNo > aa.seqNo
	) as endGap
from dbo.GapsIslands as aa
where not exists (
	select *
	from dbo.GapsIslands as bb
	where bb.seqNo = aa.seqNo + 1
)
and aa.seqNo < (
	select max(seqNo)
	from dbo.GapsIslands
)

;with cteSeq as (
	select aa.SeqNo
		,row_number() over(order by aa.SeqNo) as rownum
	from dbo.GapsIslands as aa
)
select cur.seqNo + 1 as startRange
	,nxt.seqNo - 1 as endRange
from cteSeq as cur
join cteSeq as nxt
	on cur.rownum = nxt.rownum - 1
where nxt.seqNo - cur.seqNo > 1

-----------------------------------------------------------------------------------------------------
--20150806 gaps and islands
CREATE TABLE GapsIslands (ID INT NOT NULL, SeqNo INT NOT NULL);
 
ALTER TABLE dbo.GapsIslands ADD CONSTRAINT pk_GapsIslands PRIMARY KEY (ID, SeqNo);
 
INSERT INTO dbo.GapsIslands
SELECT 1, 1 UNION ALL SELECT 1, 2 UNION ALL SELECT 1, 5 UNION ALL SELECT 1, 6
UNION ALL SELECT 1, 8 UNION ALL SELECT 1, 9 UNION ALL SELECT 1, 10 UNION ALL SELECT 1, 12
UNION ALL SELECT 1, 20 UNION ALL SELECT 1, 21 UNION ALL SELECT 1, 25 UNION ALL SELECT 1, 26; 
 
SELECT * FROM dbo.GapsIslands;


;with StartingData as (
	select SeqNo, row_number() over(order by SeqNo) as rownum
	from dbo.GapsIslands as aa
	where not exists (
		select *
		from dbo.GapsIslands as bb
		where bb.seqno = aa.seqno - 1
	)
)
, EndingData as (
	select SeqNo, row_number() over(order by SeqNo) as rownum
	from dbo.GapsIslands as aa
	where not exists (
		select *
		from dbo.GapsIslands as bb
		where bb.seqno = aa.seqno + 1
	)
)
select ss.seqNo as StartRange, ee.seqNo as EndRange
from StartingData as ss
join EndingData as ee
	on ss.rownum = ee.rownum
go

select min(SeqNo) as StartRange, max(SeqNo) as EndRange
from (
	select SeqNo
		,SeqNo - row_number() over(order by SeqNo) as SeqGroup
	from dbo.GapsIslands
) as ss
group by SeqGroup
-----------------------------------------------------------------------------------------------------
--20150806 case switch pivot table tab table
use aw2014

declare @color table (
	ColorName varchar(25)
)

insert @color
select distinct color
from production.product
where color is not null

declare @cmd varchar(max) = 'select name' + char(10)

select @cmd = @cmd + ',sum(case color when ''' 
				+ ColorName		
				+ ''' then SafetyStockLevel else 0 end) as ' 
				+ quotename(ColorName) + char(10)
from @color

set @cmd = @cmd + '
	,sum(SafetyStockLevel) as Total
	from Production.Product
	group by name
	order by name'

print @cmd 

exec(@cmd)


-----------------------------------------------------------------------------------------------------
--20150804 Quiry Update Running Total
declare @AccountIDPrev int
	,@Total money

update dbo.TransactionDetail
set @Total = CASE
					when AccountID = @AccountIDPrev
						then @Total + Amount
					else Amount
				end
	,AccountRunningTotal = @Total
	,@AccountIDPrev = AccountID
from dbo.TransactionDetail with (tablockx)
option (maxdop 1)


--=====----------------------------------------------------------------------------------------------
--===== 20150803 Have you seen this workaround lead and lag?:
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

--=====----------------------------------------------------------------------------------------------
--===== Running total sum over
use tempdb

declare @max int = 999
	,@cat int = 10

select
	identity(int, 1,1) as id
	,abs(checksum(newid())) % @cat + 1 as Category
	,abs(checksum(newid())) % @max + 1  as Cost
into dbo.TestSum
from sys.columns as aa

select
	category
	,id
	,sum(cost) over (partition by category order by id)
from dbo.TestSum
order by category, id

--=====----------------------------------------------------------------------------------------------
--===== Create tally table with padded zeros
select top 65536 row_number() over
	(order by (select null)) as NN
from sys.columns as aa 
cross join sys.columns as bb;

select  REPLICATE('0', 10 - len(NN)) + cast(NN as varchar(10))
from dbo.Tally

select right('0000000000' + cast(NN as varchar(10)), 10)
from dbo.Tally
--=====----------------------------------------------------------------------------------------------
--===== Filter random row
SELECT *
FROM dbo.Tally AS tt
WHERE NN = 1 + (
		SELECT CAST(RAND() * COUNT(*) AS INT)
		FROM dbo.Tally
		)
--=====----------------------------------------------------------------------------------------------
--===== Create random words of random length
declare @len int = 10

select
	left(replace(cast( newid() as varchar(50)), '-', '')
		,abs(checksum(newid())) % @len + 1)
from sys.columns as aa
--=====----------------------------------------------------------------------------------------------
--===== Create random int less than a max value
declare @max int = 999

select
	abs(checksum(newid())) % @max + 1 
from sys.columns as aa
--=====----------------------------------------------------------------------------------------------
--===== Sample 1% of table
SELECT * 
FROM dbo.Tally
WHERE 0.01 >= CAST(CHECKSUM(NEWID(), NN) & 0x7fffffff AS numeric(18,2)) / CAST (0x7fffffff AS int)
--=====----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--RaiseError Try Catch
BEGIN TRY
    INSERT dbo.TestRethrow(ID) VALUES(1);
--  Force error 2627, Violation of PRIMARY KEY constraint to be raised.
    INSERT dbo.TestRethrow(ID) VALUES(1);
END TRY
BEGIN CATCH

    PRINT 'In catch block.';
    THROW;
END CATCH;

------------------------------------------------------------------------------------------------------
--20150722 Character Tally Table
;with CharTally as (
	select 0 as Num
		,char(0) as Chr
	union all
	select Num + 1
		,char(Num + 1)
	from CharTally
	where Num < 255
)
select * 
into dbo.CharTally
from CharTally
option (maxrecursion 255)

------------------------------------------------------------------------------------------------------
--20150722 Number Tally table
SELECT TOP 1000000 IDENTITY(int,1,1) AS Number
    INTO dbo.TallyTest
    FROM sys.tables s1
    CROSS JOIN sys.columns s2

select top 1000000 row_number() over(order by (select null)) as N
into dbo.TallyTest2
from   sys.tables t1 
       cross join sys.columns t2

;WITH Tally (N) AS
(
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.tables a CROSS JOIN sys.columns b
)
SELECT TOP 1000000 N
into dbo.TallyTest3
FROM Tally;


------------------------------------------------------------------------------------------------------
--20150716 unpivot by cross join

To preserve NULLs, use CROSS JOIN ... CASE:

select a.ID, b.column_name
, column_value = 
    case b.column_name
      when 'col1' then a.col1
      when 'col2' then a.col2
      when 'col3' then a.col3
      when 'col4' then a.col4
    end
from (
  select ID, col1, col2, col3, col4 
  from table1
  ) a
cross join (
  select 'col1' union all
  select 'col2' union all
  select 'col3' union all
  select 'col4'
  ) b (column_name)
Instead of:

select ID, column_name, column_value
From (
  select ID, col1, col2, col3, col4
  from from table1
  ) a
unpivot (
  column_value FOR column_name IN (
    col1, col2, col3, col4)
  ) b
A text editor with column mode makes such queries easier to write. UltraEdit has it, so does Emacs. In Emacs it''s called rectangular edit.

You might need to script it for 100 columns.
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
------------------------------------------------------------------------------------------------------
--20150716 sql to html static
ALTER PROC [dbo].[spACO_incoming_file_overview]

AS

/* create html */
DECLARE @HTML VARCHAR(MAX), @TR varchar(9)
SET @TR = '</td><td>'

SET @HTML = '<html>' +
				'<head></head><title></title>' + 
					'<body>' + 
						'<table>' +
							'<tr style="background-color: #5D7B9D; font-weight: bold; color: white;">' +
								'<td>Sourcefile</td>' +
								'<td>TotalDollars</td>' +
								'<td>MinServiceDate</td>' +
								'<td>MaxServiceDate</td>' +
								'<td>MinPaidDate</td>' +
								'<td>MaxPaidDate</td>' +
								'<td>TotalRows</td>' +
								'<td>NewRows</td>' +
								'<td>PY1</td>' +
								'<td>PY2</td>' +
								'<td>PY3</td>' +
								'<td>PY4</td>' +
							'</tr>';

/* fill html */
SELECT @HTML = @HTML + 
	CASE ROW_NUMBER() OVER (ORDER BY RowID)%2
		WHEN  0 THEN '<tr style="background-color: #F7F6F3"><td>' + Sourcefile + @TR
		ELSE '<tr><td>' + Sourcefile + @TR
	END
	+ REPLACE(CAST(TotalDollars AS VARCHAR(20)),'0.00','')
	+ @TR + MinServiceDate
	+ @TR + MaxServiceDate
	+ @TR + MinPaidDate
	+ @TR + MaxPaidDate
	+ @TR + CAST(TotalRows AS VARCHAR(10))
	+ @TR + CAST(NewRows AS VARCHAR(10))
	+ @TR + PY1
	+ @TR + PY2
	+ @TR + PY3
	+ @TR + PY4
FROM dbo.Stage_ClaimsLoad_Summary

/* finish html */
SELECT @HTML = @HTML + '</table></body></html>'
		
/* html output */
INSERT INTO dbo.Stage_ClaimsLoad_HTML(HTML, LoadDate) 
OUTPUT inserted.HTML
VALUES (@HTML, GETDATE())


select * from dbo.Stage_ClaimsLoad_HTML

------------------------------------------------------------------------------------------------------
--20150716 ms_foreachdb cursor 
declare @sql varchar(1000)
declare @db SYSNAME

declare curDB cursor forward_only static FOR
	select name
	from master.sys.databases
	where name not in ('model', 'tempdb')
	order by name

open curDB
fetch next from curDB into @db
while @@fetch_status = 0
	BEGIN
		select @sql = 'use [' + @db + ']' + char(13) + 'exec sp_updatestats' + char(13)
		print @sql
		fetch next from curDB into @db
	END

close curDB
deallocate curDB
------------------------------------------------------------------------------------------------------
--20150707 ms_foreachdb cursor
DECLARE @SQL VARCHAR(1000)  
DECLARE @DB sysname  

DECLARE curDB CURSOR FORWARD_ONLY STATIC FOR  
   SELECT [name]  
   FROM master..sysdatabases 
   WHERE [name] NOT IN (‘model’, ‘tempdb’) 
   ORDER BY [name] 
     
OPEN curDB  
FETCH NEXT FROM curDB INTO @DB  
WHILE @@FETCH_STATUS = 0  
   BEGIN  
       SELECT @SQL = ‘USE [' + @DB +']‘ + CHAR(13) + ‘EXEC sp_updatestats’ + CHAR(13)  
       PRINT @SQL  
       FETCH NEXT FROM curDB INTO @DB  
   END  
    
CLOSE curDB  
DEALLOCATE curDB

------------------------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------------------------
--20150707 Html 
USE [ACO_Report]
GO
/****** Object:  StoredProcedure [dbo].[spHF_Mail_ValidFail]    Script Date: 7/6/2015 3:30:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spHF_Mail_ValidFail]
AS
BEGIN

    DECLARE @HTML VARCHAR(8000)
	    ,@TR VARCHAR(9)

    SET @TR = '</td><td>'
    SET @HTML = '<html>' +
				    '<head></head><title></title>' + 
					    '<body>' + 
						    '<table>' +
							    '<tr style="background-color: #5D7B9D; font-weight: bold; color: white;">' +
								    '<td>Compname</td>' +
								    '<td>Actper</td>' +
								    '<td>Effper</td>' +
								    '<td>ClaimType</td>' +
								    '<td>Amount_HF</td>' +
								    '<td>Amount_Ctrl</td>' +
								    '<td>Comment</td>' +
								    '<td>ts</td>' +
							    '</tr>';

    SELECT @HTML = @HTML +
	    CASE ROW_NUMBER() OVER (ORDER BY ClaimID) % 2
		    WHEN 0
			    THEN '<tr style="background-color: #F7F6F3"><td>' + Compname
		    ELSE '<tr><td>' + Compname
	    END
	    + @TR + Actper
	    + @TR + Effper
	    + @TR + ClaimType
	    + @TR + isnull(cast(Amount_HF as varchar(50)),'')
	    + @TR + isnull(cast(Amount_Ctrl as varchar(50)),'')
	    + @TR + Comment
	    + @TR + cast(ts as varchar(50))
    FROM dbo.Stage_HealthFirst_Mismatch
    ORDER BY Compname, ClaimType

    SELECT @HTML = @HTML + '</td></tr></table></body></html>'
    SELECT @HTML as HTML
    
    --INSERT INTO dbo.HealthFirst_Mismatch_HTML(HTML, LoadDate) 
    --OUTPUT inserted.HTML
    --VALUES (@HTML,getdate())

	--CREATE TABLE dbo.HealthFirst_Mismatch_HTML (
	--    RowID INT identity(1, 1)
	--    ,LoadDate DATETIME
	--    ,HTML VARCHAR(max)
	--    ,Processed INT
	--)
END

select * FROM dbo.Stage_HealthFirst_Mismatch
------------------------------------------------------------------------------------------------------
--20150622 run ssrs job
EXEC msdb.dbo.sp_start_job '53A153F5-0C40-469A-988D-0C12245E38ED'
------------------------------------------------------------------------------------------------------
--20150622 unpivot vs cross apply vs cross join
select  sourc.MBR_NUM
	, xapp.ques
	, xapp.ans
from stage.TblHRAMedicaid as sourc
cross apply (
	values ('q1', q1), ('q2', q2a), ('q2b', q2b), ('q3', q3), ('q4', q4), ('q5', q5)
) as xapp(ques, ans)
go

select  unpiv.MBR_NUM
	, unpiv.ques
	, unpiv.ans
from stage.TblHRAMedicaid as sourc
unpivot (
	ans for ques in (q1, q2a, q2b, q3, q4, q5)
) as unpiv
go

select sourc.mbr_num
	, xjoin.ques
	, case xjoin.ques
		when 'q1' then sourc.q1
		when 'q2a' then sourc.q2a
		when 'q2b' then sourc.q2b
		when 'q3' then sourc.q3
		when 'q4' then sourc.q4
		when 'q5' then sourc.q5
	end as ans
from stage.TblHRAMedicaid as sourc
cross join (
	values ('q1'), ('q2a'), ('q2b'), ('q3'), ('q4'), ('q5')
) as xjoin(ques)
go

------------------------------------------------------------------------------------------------------
--20150622 unpivot example
SELECT CustomerID, Phone
FROM
(
  SELECT CustomerID, Phone1, Phone2, Phone3 
  FROM dbo.CustomerPhones
) AS cp
UNPIVOT 
(
  Phone FOR Phones IN (Phone1, Phone2, Phone3)
) AS up;
------------------------------------------------------------------------------------------------------
--20150622 cross join unpivot
To preserve NULLs, use CROSS JOIN ... CASE:

select a.ID, b.column_name
, column_value = 
    case b.column_name
      when 'col1' then a.col1
      when 'col2' then a.col2
      when 'col3' then a.col3
      when 'col4' then a.col4
    end
from (
  select ID, col1, col2, col3, col4 
  from table1
  ) a
cross join (
  select 'col1' union all
  select 'col2' union all
  select 'col3' union all
  select 'col4'
  ) b (column_name)
Instead of:

select ID, column_name, column_value
From (
  select ID, col1, col2, col3, col4
  from from table1
  ) a
unpivot (
  column_value FOR column_name IN (
    col1, col2, col3, col4)
  ) b
A text editor with column mode makes such queries easier to write. UltraEdit has it, so does Emacs. In Emacs it''s called rectangular edit.

You might need to script it for 100 columns.

------------------------------------------------------------------------------------------------------
--20150619 cross join unpivot

To preserve NULLs, use CROSS JOIN ... CASE:

select a.ID, b.column_name
, column_value = 
    case b.column_name
      when 'col1' then a.col1
      when 'col2' then a.col2
      when 'col3' then a.col3
      when 'col4' then a.col4
    end
from (
  select ID, col1, col2, col3, col4 
  from table1
  ) a
cross join (
  select 'col1' union all
  select 'col2' union all
  select 'col3' union all
  select 'col4'
  ) b (column_name)
Instead of:

select ID, column_name, column_value
From (
  select ID, col1, col2, col3, col4
  from from table1
  ) a
unpivot (
  column_value FOR column_name IN (
    col1, col2, col3, col4)
  ) b
A text editor with column mode makes such queries easier to write. UltraEdit has it, so does Emacs. In Emacs it's called rectangular edit.'

You might need to script it for 100 columns.
------------------------------------------------------------------------------------------------------
--20150619 

SELECT * FROM sys.dm_os_wait_stats
EXEC sp_who2
------------------------------------------------------------------------------------------------------
--20150618 cross apply median

select top 100 * from sales.salesorderdetail

--create index ix_productid_orderqty on sales.salesorderdetail (productid, orderqty)

;with c_sod as (
	select productid,  count (*) as cnt
		, (count (*) - 1) / 2 as ov
		, 2 - (count (*)) % 2 as fv
	from sales.salesorderdetail sod
	group by productid
)
SELECT c_sod.productid, avg(1.0 * x_row.orderqty) as median
from c_sod
cross apply (
	SELECT s_sod.orderqty
	from sales.salesorderdetail as s_sod
	where s_sod.productid = c_sod.productid
	order by s_sod.orderqty
	offset c_sod.ov rows fetch next c_sod.fv rows only) as x_row(orderqty)
group by c_sod.productid

------------------------------------------------------------------------------------------------------
--20150617 TST Tool test driven development

alter function dbo.fnTiny01(
	@tiny tinyint
)
returns varchar(100)
as
begin

	declare @i int = @tiny
	declare @result varchar(32) = space(0)

	while @i > 0 begin
		select @result = cast(@i % 2 as char(1)) + @result
			, @i = cast(@i / 2 as int)
	end
	return @result
end

/*Test fragment for validating dbo.fnTiny01

declare @actual varchar(10) = dbo.fntiny01(11)
if(@actual = '1011') print 'passed'
else print 'failed'
*/

/*
	Procedure SQLTest_dbo_fnTiny01
*/
alter proc dbo.SQLTest_dbo_fnTiny01
as begin
	declare @binary varchar(10)

	set @binary = dbo.fnTiny01(null)
	exec tst.assert.isnull 'case: null', @binary
	
	set @binary = dbo.fnTiny01(11)
	exec TST.Assert.Equals 'Case: 11', '1011', @binary
end

exec tst.runner.runall dbzoo
------------------------------------------------------------------------------------------------------
--20150605 rollup cube grouping

select grouping(saledate),saledate
	,grouping(category),category
	,count(*)
from @sales
group by rollup(saledate, category)

select grouping(saledate),saledate
	,grouping(category),category
	,count(*)
from @sales
group by cube(saledate, category)

------------------------------------------------------------------------------------------------------
--20150604 nested aggregate max sale per year per quarter
 declare @sales table(
	id int identity(1,1)
	,category varchar(50)
	,saledate smalldatetime
	,amount money
 )

 insert @sales(
	category
	,saledate
	,amount
 )
 values
	('green','19990101', 10)
	,('blue','19990101', 30)
	,('red','19990601', 20)
	,('seven','19990601', 50)
	,('eleven','19990601', 500)
	,('rice','19990901', 100)
	,('wheat','19990901', 1000)
	,('pc','19991201', 10)
	,('mac','19991201', 100)
	,('android','19991201', 5000)

SELECT sub2.yr
	,sub2.qtr
	,cat.category
	,sub2.maxtotal
from(
	select sub.yr
		,sub.qtr
		,max(sub.total) as maxtotal
	from(
		select category
			,year(saledate) as yr
			,datepart(quarter, saledate) as qtr
			,sum(amount) as total
		from @sales
		group by category
			,year(saledate)
			,datepart(quarter, saledate)
		) as sub
	group by sub.yr
		,sub.qtr
	) as sub2
	join(
		select category
			,year(saledate) as yr
			,datepart(quarter, saledate) as qtr
			,sum(amount) as total
		from @sales
		group by category
			,year(saledate)
			,datepart(quarter, saledate)
	) as cat
on sub2.yr = cat.yr
	and sub2.qtr = cat.qtr
	and sub2.maxtotal = cat.total


------------------------------------------------------------------------------------------------------
--20150604 
avg will ignore nulls
use sum(field) / count(*) to include nulls

union all
vs
select distinct


----------------------------------------------------------------------------------------------------
20150528 cross apply ben gan itzik

TOP N Per Group

index poco
Partition	: custid
Ordering	: orderdate desc, orderid desc	tie breaker
COvering	: empid							returned

create index idx_poc on sales.orders(custid, orderdate desc, orderid desc) include(empid)


execution plans

data flow order (right)
vs.
internal execute order (left root)
	invokes api -> give me a row


create index idx_poco
on sales.salesorderheader (
	customerid
	,orderdate desc
	,salesorderid desc
)
include (
	salespersonid
);

with caa as (
	select 
		CustomerID as custid
		,OrderDate as odate
		,SalesOrderID as saleid
		,salespersonid as personid
		,row_number() over(
			partition by CustomerID
			order by OrderDate
					,salesorderid
		) as rownum
	from sales.SalesOrderHeader
)
select custid, odate, saleid, personid
from caa
where rownum <= 3;

select so.CustomerID
	,so.orderdate
	,so.SalesOrderID
	,so.SalesPersonID
from sales.salesorderheader as so
outer apply sales.gettoporder(so.customerid, 3) as zz

go
alter function sales.getTopOrder (
	@custid as int
	,@n as int
)
returns table
as
return
	
	select top(@n)
		so.orderdate
		,so.SalesOrderID
		,so.SalesPersonID
	from sales.salesorderheader as so
	where so.customerid = @custid;
go


----------------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------------
914-378-6093

------------------------------------------------------------------------------------------------------
--20150604 get aggregate field in select without group by use subquery

select sq.category
	,categoryname
	,sq.sum
	,sq.avg
from (
	select category
		,sum(amount)
		,avg(amount)
	from rawdata
	group by category
) as sq
join rawcategory as c
	on sq.category = c.rawcategoryid
order by category
	,categoryname

------------------------------------------------------------------------------------------------------
--20150604 relational division

declare @pilotXplane table (
	pilot varchar(50)
	,plane varchar(50)	
)

insert @pilotXplane (
	pilot
	,plane
)
values ('Celko', 'Piper Cub')
,('Higgins', 'B-52 Bomber')
,('Higgins', 'F-14 Fighter')
,('Higgins', 'Piper Cub')
,('Jones', 'B-52 Bomber')
,('Jones', 'F-14 Fighter')
,('Smith', 'B-1 Bomber')
,('Smith', 'B-52 Bomber')
,('Smith', 'F-14 Fighter')
,('Wilson', 'B-1 Bomber')
,('Wilson', 'B-52 Bomber')
,('Wilson', 'F-14 Fighter')
,('Wilson', 'F-17 Fighter')

declare @plane table (
	plane varchar(50)
)
insert @plane (
	plane
)
values ('B-1 Bomber')
	,('B-52 Bomber')
	,('F-14 Fighter')
	--,('Tie Fighter')


select distinct pilot
from @pilotXplane as pp1
where not exists (
	select *
	from @plane as ll
	where not exists (
		select *
		from @pilotXplane as pp2
		where pp1.pilot = pp2.pilot
			and ll.plane = pp2.plane
	)
)

select pilot
from @pilotXplane as pp
join @plane as ll
	on pp.plane = ll.plane
group by pilot
having count(pp.plane) = (
	select count(ll.plane)
	from @plane
)

/*
SELECT DISTINCT x.A
FROM T1 AS x
WHERE NOT EXISTS (
                  SELECT *
                  FROM  T2 AS y
                  WHERE NOT EXISTS (
                                     SELECT *
                                     FROM T1 AS z
                                     WHERE (z.A=x.A) AND (z.B=y.B)
                                   )
                 );

SELECT A
FROM T1
WHERE B IN ( 
             SELECT B
             FROM T2 
           )
GROUP BY A
HAVING COUNT(*) = ( 
                    SELECT COUNT (*)
                    FROM T2
                  );
*/

------------------------------------------------------------------------------------------------------
--20150604 relational division

declare @student table (
	sid int identity(1,1)
	,name varchar(50)
)

insert @student (
	name
)
values ('bill')
	,('may')
	,('april')
	,('june')
	,('sally')

declare @class table (
	cid int identity(1,1)
	,title varchar(50)
	,require bit default 0
)

insert @class (
	title
	,require
)
values ('engineering', 1)
	,('psionics', 1)
	,('combat', 1)
	,('healing', 1)
	,('negotiation', 0)
	,('gardening', 0)
	

declare @classXstudent table (
	cid int
	,sid int
)

insert @classXstudent (
	cid
	,sid
)
values (1,2)
	,(1,3)
	,(1,4)
	,(2,2)
	,(2,3)
	,(2,4)
	,(3,2)
	,(3,3)
	,(3,4)
	,(1,5)
	,(2,5)
	,(3,5)
	,(4,2)
	,(4,3)
	,(4,4)
	,(4,1)
	,(5,2)
	,(6,2)
	,(5,5)
	,(5,1)
	,(1,1)
	,(2,1)


select 
	ss.sid
	,count(distinct cc.cid) as countclass
from @student as ss
join @classXstudent as cs
	on ss.sid = cs.sid
join @class as cc
	on cs.cid = cc.cid
where cc.require = 1
group by ss.sid
having count(distinct cc.cid) = (
	SELECT count(*)
	from @class as cc2
	where require  = 1
)

------------------------------------------------------------------------------------------------------
--20150602 xml query value nodes
declare @var xml = 
'<?xml version="1.0" ?>
<document xmlns="http://www.brokenwire.net/xmldemo">
  <header>Alphabet</header>
  <items>
    <item id="a">a is for apple</item>
    <item id="b">b is for balloon</item>
  </items>
</document>'

insert @tbl (
	col
)
values (@var)

declare @tbl table (
	col xml
)

declare @var xml = 
'<?xml version="1.0" ?>
<root xmlns = "http://www.brokenwire.net/xmldemo">
  <header>Alphabet</header>
  <items>
    <item id="a">a is for apple</item>
    <item id="b">b is for balloon</item>
  </items>
</root>'

insert @tbl (
	col
)
values (@var)


select col.value('declare namespace bw="http://www.brokenwire.net/xmldemo";(/bw:root/bw:items/bw:item)[2]', 'varchar(50)')
from @tbl

SELECT col.query('declare namespace bw="http://www.brokenwire.net/xmldemo";(/bw:root/bw:items/bw:item)[@id = "a"]')
from @tbl

SELECT col.exist('declare namespace bw="http://www.brokenwire.net/xmldemo";(/bw:root/bw:items/bw:item)[1]')
from @tbl

select col.exist('declare namespace bw="http://www.brokenwire.net/xmldemo";(/bw:root/bw:items/bw:item)[.="a is for apple"]')
from @tbl

select col.exist('declare namespace bw="http://www.brokenwire.net/xmldemo";(/bw:root/bw:items/bw:item)[contains(.,"apple")]')
from @tbl


update @tbl
set col.modify('insert <item id="c">c is for cherry</item> as last into (/root/items)[1]')

update @tbl
set col.modify('delete (/root/items/item)[1]')

update @tbl
set col.modify('delete (/root/items/item)[@id = "b"]')


;with xmlnamespaces(
	'http://www.brokenwire.net/xmldemo' as ns
)
update @tbl
set col.modify('replace value of (/ns:root/ns:items/ns:item)[1] with "c is for cool"')


CREATE XML SCHEMA COLLECTION ClientInfoCollection AS 
'<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
xmlns="urn:ClientInfoNamespace" 
targetNamespace="urn:ClientInfoNamespace" 
elementFormDefault="qualified">
  <xsd:element name="People">
    <xsd:complexType>
      <xsd:sequence>
        <xsd:element name="Person" minOccurs="1" maxOccurs="unbounded">
          <xsd:complexType>
            <xsd:sequence>
              <xsd:element name="FirstName" type="xsd:string" minOccurs="1" maxOccurs="1" />
              <xsd:element name="LastName" type="xsd:string" minOccurs="1" maxOccurs="1" />
              <xsd:element name="FavoriteBook" type="xsd:string" minOccurs="0" maxOccurs="5" />
            </xsd:sequence>
            <xsd:attribute name="id" type="xsd:integer" use="required"/>
          </xsd:complexType>
        </xsd:element>
      </xsd:sequence>
    </xsd:complexType>
  </xsd:element>
</xsd:schema>'
GO

select
	zz.node.query('.')
	,zz.node.value('../header', varchar(50))
	,zz.node.query('(@id)', varchar(50))
from @tbl as aa
cross apply col.nodes('/root/items/item') as zz(node)
------------------------------------------------------------------------------------------------------
--20150602 running total

CREATE TABLE dbo.testdata (
   id    int not null identity(1,1) primary key,
   value int not null
);
----------------------------------
-- test data
--------------------------------------------------------------------
INSERT INTO testdata (value) VALUES (1);
INSERT INTO testdata (value) VALUES (2);
INSERT INTO testdata (value) VALUES (4);
INSERT INTO testdata (value) VALUES (7);
INSERT INTO testdata (value) VALUES (9);
INSERT INTO testdata (value) VALUES (12);
INSERT INTO testdata (value) VALUES (13);
INSERT INTO testdata (value) VALUES (16);
INSERT INTO testdata (value) VALUES (22);
INSERT INTO testdata (value) VALUES (42);
INSERT INTO testdata (value) VALUES (57);
INSERT INTO testdata (value) VALUES (58);
INSERT INTO testdata (value) VALUES (59);
INSERT INTO testdata (value) VALUES (60);

--correlated subquery
select aa.id
	,aa.value
	,zz.total
from dbo.testdata as aa
cross apply (
	select SUM(bb.value)
	from dbo.testdata as bb
	where bb.id <= aa.id
) as zz(total)

--cross join
SELECT
	aa.id
	,aa.value
	,sum(bb.value)
from dbo.testdata as aa
cross join dbo.testdata as bb
where bb.id <= aa.id
group by aa.id
	,aa.value

--sql server 2012 over clause
select
	aa.id
	,aa.value
	,sum(aa.value) over (order by aa.id)
from dbo.testdata as aa

--cursor
declare @tbl_temp table (
	id int
	,value int
	,total int
)

declare @id int
	,@value int
	,@total int = 0

declare cur_testdata cursor
for
select id
	,value
from dbo.testdata

open cur_testdata

fetch next from cur_testdata into @id, @value

while @@fetch_status = 0
begin

	set @total = @total + @value
	insert @tbl_temp (
		id
		,value
		,total
	)
	values (@id, @value, @total)
	fetch next from cur_testdata into @id, @value
end

close cur_testdata
deallocate cur_testdata

select * from @tbl_temp
go

/*************************************************************************************
 Pseduo-cursor update using the "Quirky Update" to calculate both Running Totals and
 a Running Count that start over for each AccountID.
 Takes 24 seconds with the INDEX(0) hint and 6 seconds without it on my box.
*************************************************************************************/
--===== Supress the auto-display of rowcounts for speed an appearance
   SET NOCOUNT ON

--===== Declare the working variables
DECLARE @PrevAccountID       INT
DECLARE @AccountRunningTotal MONEY
DECLARE @AccountRunningCount INT

--===== Update the running total and running count for this row using the "Quirky 
     -- Update" and a "Pseudo-cursor". The order of the UPDATE is controlled by the
     -- order of the clustered index.
 UPDATE dbo.TransactionDetail 
    SET @AccountRunningTotal = AccountRunningTotal = CASE 
														 WHEN AccountID = @PrevAccountID THEN @AccountRunningTotal + Amount 
														 ELSE Amount 
                                                     END,
        @AccountRunningCount = AccountRunningCount = CASE 
														 WHEN AccountID = @PrevAccountID THEN @AccountRunningCount + 1 
														 ELSE 1 
                                                     END,
        @PrevAccountID = AccountID
   FROM dbo.TransactionDetail WITH (TABLOCKX)
 OPTION (MAXDOP 1)
GO

----------------------------------------------------------------------------------------------------
--20150602 median fetch offset 

create table dbo.Median(
	id int
	,grp int
	,val int
)

insert dbo.median (
	id
	,grp
	,val
)
values (2,1,10)
	,(1,1,30)
	,(3,1,100)
	,(7,2,10)
	,(5,2,60)
	,(4,2,65)
	,(6,2,65)

select distinct
	grp
	,percentile_cont(0.5) within group (order by val) over (partition by grp) as median
from dbo.median;


with caa as (
	select grp
		,count(*) as cnt
		,(count(*) - 1) /2 as oo
		,2 - count(*) % 2 as ff
	from dbo.median
	group by grp
)
select caa.grp, avg(1.0 * zz.val)
from caa
	cross apply (
		select im.val
		from dbo.Median as im
		where im.grp = caa.grp
		order by im.val
		offset caa.oo rows fetch next caa.ff rows only) as zz
group by caa.grp;


----------------------------------------------------------------------------------------------------
--20150512 having count distinct to find records with 2 or more different values in a field
SELECT 
	[PatientControlNumber] AS ClaimID
	,count(*)
FROM [DAR_Raw_Data].[raw].[HealthFirst_P14_History]
group by [PatientControlNumber] 
having count(distinct [MemberNumber]) > 1

declare @temp table(
	id int
	,name varchar(50)
)

insert @temp(
	id
	,name
)
values (1,'apple')
	,(1,'pear')
	,(2,'steak')
	,(3,'juice')
	,(3,'juice')
	,(4,'humus')
	,(5,'salmon')
	,(6,'cinnamon')
	,(7,'brownie')
	,(8,'maple')
	,(9,'wheat')
	,(9,'barley')
	,(9,'quinoa')

select id, count(*)
from @temp
group by id
having count(distinct name) > 1

select id, count(*)
from(
	select DISTINCT
		id
		,name
	from @temp
) as tt
group by id
having count(*) > 1

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
--20150430 parse delimited text
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
--20150805
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
--(
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
ORDER BY COUNT(*) DESCf
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
--20150722 Clean up while stuff loop
declare @keepvalue varchar(100)
      ,@temp varchar(100) 
set @keepvalue = '%[^a-z]%'
set @temp = 'dihijs350klj180[\\]'

while patindex(@keepvalue, @temp) > 0
begin

      set @temp = stuff(@temp, patindex(@keepvalue, @temp), 1, space(0))

end

select @temp

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

--20141024 sqlvariantproperty

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
-- 20150804 Running Total Cursor UNUSABLE
declare @AccountIDCur int
	,@Amount money
	,@AccountIDPrev int
	,@Total money

declare curRunningSum cursor
for
select AccountID, Amount
from dbo.TransactionDetail
order by AccountID, Date, TransactionDetailID

open curRunningSum
fetch next from curRunningSum
into @AccountIDCur, @Amount

while @@fetch_status = 0
begin

	select @Total = CASE
						when @AccountIDCur = @AccountIDPrev then @Total + @Amount
						else @Amount
					end
			,@AccountIDPrev = @AccountIDCur
	
	update dbo.TransactionDetail
	set AccountRunningTotal = @Total
	where current of curRunningSum

	fetch next from curRunningSum
	into @AccountIDCur, @Amount

end

close curRunningSum
deallocate curRunningSum
------------------------------------n----------------------------------------------------------------
-- 20150804 Running Total Verify Sproc
create proc dbo.VerifyRun
as
begin

	if object_id('TempDB.dbo.#Verify') is not null
		drop table dbo.#Verify

	declare @MyCount int

	select identity(int, 1, 1) as RowNum
		,AccountID
		,Amount
		,AccountRunningTotal
	into dbo.#Verify
	from dbo.TransactionDetail
	order by AccountID, Date, TransactionDetailID

	set @MyCount = @@rowcount

	SELECT CASE
				when count(hi.RowNum) + 1 = @MyCount
					then 'Running Total Correct'
				else 'Error in Running Total'
		end
	from dbo.#Verify as hi
	join dbo.#Verify as lo
		on hi.RowNum - 1 = lo.RowNum
	where (hi.AccountID = lo.AccountID and hi.AccountRunningTotal = lo.AccountRunningTotal + hi.Amount)
	or (hi.AccountID <> lo.AccountID and hi.AccountRunningTotal = hi.Amount)

end
----------------------------------------------------------------------------------------------------
