
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

