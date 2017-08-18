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
-----------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------
declare @x xml
set @x = '<root>
			<row id="1"><name>Larry</name></row>
			<row id="2"><name>Moe</name></row>
			<row id="3"><name>Curly</name></row>
		</root>'

select T.c.query('.')
from @x.nodes('/root/row') as T(c)
-----------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------
--20150421
Four uses of xml:
1. run function on every row
2. shred xml
3. impivot columns
4. reuse computed columns
---------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------
--batch insert
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
-- Set the @rowcounter to the next batch start
SET @rowcounter = @rowcounter + @batch + 1;
END
----------------------------------------------------------------------------------

--20150903 dynamic sql get all columns in table
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
--------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------------
--20150831 Calculate Age
declare
	@dob datetime = '2014-09-01'

SELECT
	case 
		when dateadd(yy, datediff(yy, @dob, getdate()), @dob) > getdate()
			then datediff(yy, @dob, getdate()) - 1
		else datediff(yy, @dob, getdate())
	end
-------------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------
--20150604 
avg will ignore nulls
use sum(field) / count(*) to include nulls

union all
vs
select distinct
----------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------
declare @filePeriod varchar(20)
		,@nameReverse varchar(50) = reverse(@fileName)

select 
	@filePeriod = reverse(substring(aa.nameReverse, bb.position + 1, 13))
from (
	values(@nameReverse)
) as aa(nameReverse)
cross apply (
	select charindex('.',aa.nameReverse)) as bb(position)
-------------------------------------------------------------------------------------------
--remove non alphanumeric characters
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
-----------------------------------------------------------------------------------
--20141204 cleanup characters
--A way to identify how dirty our data in the member mart really is (looking for non-alphabet characters)

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
----------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--Have you seen this? Why is yours 45 lines long! It’s cool, I’m only a little disappointed.

declare @keepvalue varchar(100)
      ,@temp varchar(100) 
set @keepvalue = '%[^a-z]%'
set @temp = 'dihijs350klj180[\\]'

while patindex(@keepvalue, @temp) > 0
begin

      set @temp = stuff(@temp, patindex(@keepvalue, @temp), 1, space(0))

end

select @temp
----------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------
20141121 cleanup numbers zipcode


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
-------------------------------------------------------------------------------------------
--201410010 cleanziptallytable

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
----------------------------------------------------------------------------------------------
--You can use this function to split strings (any separator as long as it’s a singe character, for example “,”, “|” or TAB). Might come in handy.

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
-------------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------------
--20141204 concatenate

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
--20150810 tally table table of dates
--------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------
20140904 pivot unpivot

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

-------------------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------------
--20141006 find gap in a sequence
--In MySQL and PostgreSQL:

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
---------------------------------------------------------------------------------------------
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
/*
A text editor with column mode makes such queries easier to write. 
UltraEdit has it, so does Emacs. In Emacs it''s called rectangular edit.
You might need to script it for 100 columns.*/
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
----------------------------------------------------------------------------------------------
--20150804 Query Update Running Total
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
----------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------------
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
---------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------------------
--20141023 create tally table

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

--------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------------
--20150602 running total

CREATE TABLE dbo.testdata (
   id    int not null identity(1,1) primary key,
   value int not null
);

-- test data
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
---------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------
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
select * from cteaa
-------------------------------------------------------------------------------------------
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

----------------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--20150511 don't use count(*)
SELECT COUNT(*) FROM dbo.table;

SELECT SUM(rows) FROM sys.partitions 
WHERE index_id IN (0,1) AND [object_id] = …
--------------------------------------------------------------------------------
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

-----------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--20141224 parse delimited string recursive cte

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
---------------------------------------------------------------------------------------
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
----------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------
--20150429
sp_msforeachdb 'select "?" AS db, * from [?].sys.tables where name like ''tblhhtotal%'''
-----------------------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------------
--20150805 temp table dynamic
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
------------------------------------------------------------------------------------
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

------------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------------
--20150210 temp table dates

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
------------------------------------------------------------------------------------------------
--20140904 remove duplicates
--There are basically 4 techniques for this task, all of them standard SQL.

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
--------------------------------------------------------------------------------------

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
--------------------------------------------------------------------------------------
--20141001 temp table table variable
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
------------------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
--20150606 waitfor delay
print 'hello'
waitfor delay '00:00:02'
print 'buy'
---------------------------------------------------------------------------------
--lead lag 20151001
select lead(empid,2,'999') over(order by empname), empid
from dbo.employees