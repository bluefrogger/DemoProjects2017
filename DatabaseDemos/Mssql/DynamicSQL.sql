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
--------------------------------------------------------------------------------
--Table Partitioning
--Listing 1: Code to Create Two Partitions on the DEFAULT File Group
USE testdb;
GO

CREATE PARTITION FUNCTION pfArchive (TINYINT) AS RANGE LEFT
FOR
VALUES (0);
GO

CREATE PARTITION SCHEME psArchive AS PARTITION pfArchive ALL TO ([DEFAULT]);
GO

--Listing 2: Code to Create a Customer Table on the psArchive Partition Scheme
USE testdb;
GO

CREATE TABLE dbo.Customer (
	CustomerId INT CONSTRAINT pkCustomer PRIMARY KEY
	,NAME VARCHAR(60)
	,ArchiveIndicator TINYINT
	) ON psArchive (ArchiveIndicator);

--Listing 3: Code to Place Index Directly on a Specific File Group
CREATE TABLE dbo.Customer (
	CustomerId INT CONSTRAINT pkCustomer PRIMARY KEY NONCLUSTERED ON [PRIMARY]
	,NAME VARCHAR(60)
	,ArchiveIndicator TINYINT
	) ON psArchive (ArchiveIndicator);

--Listing 4 : Query to return number of partitions per table
SELECT (
		SELECT COUNT(1)
		FROM sys.partitions AS p
		WHERE t.object_id = p.object_id
		) AS PartitionCount
	,OBJECT_SCHEMA_NAME(t.object_id) + '.' + t.NAME AS TableName
FROM sys.TABLES AS t
ORDER BY PartitionCount DESC;

--Listing 5: Code to Create a Table Filled with Test Data
CREATE TABLE dbo.PartitionTest (
	archiveIndicator TINYINT NOT NULL DEFAULT 0
	,id INT IDENTITY(1, 1)
	,IndexFill CHAR(888) NOT NULL DEFAULT ''
	,PageFill CHAR(7100) NOT NULL DEFAULT ''
	,CONSTRAINT PartitionTestCI UNIQUE CLUSTERED (
		id
		,archiveIndicator
		,IndexFill
		)
	,
	) ON psArchive (archiveIndicator);
GO

SET NOCOUNT ON;
GO

INSERT INTO dbo.PartitionTest (archiveIndicator)
VALUES (0)
	,(1);GO 40

--Listing 6 : Code to Show index Size and Deepness Information for the PartitionTest table

SELECT OBJECT_SCHEMA_NAME(object_id) + '.' + OBJECT_NAME(object_id) AS TableName
	,index_type_desc
	,alloc_unit_type_desc
	,partition_number
	,index_depth
	,index_level
	,page_count
	,record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('dbo.PartitionTest'), NULL, NULL, 'DETAILED');

--Listing 7: Code to Measure the Cost of Data Access in the PartitionTest Table
IF OBJECT_ID('tempdb..#readCount') IS NOT NULL
	DROP TABLE #readCount;

CREATE TABLE #readCount (
	archiveIndicator INT NOT NULL
	,id INT PRIMARY KEY
	,logical_reads_0 INT
	,logical_reads_1 INT
	,logical_reads_X INT
	);

INSERT INTO #readCount (
	archiveIndicator
	,id
	)
SELECT archiveIndicator
	,id
FROM dbo.PartitionTest;
GO

DECLARE cur CURSOR LOCAL FORWARD_ONLY
FOR
SELECT id
FROM #readCount
ORDER BY id
FOR UPDATE;

DECLARE @id INT;
DECLARE @dummy VARCHAR(MAX);
DECLARE @logical_reads INT;
DECLARE @rowCount INT;

OPEN cur;

FETCH NEXT
FROM cur
INTO @id;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	DBCC DROPCLEANBUFFERS;

	DBCC FREEPROCCACHE;

	DBCC FREESYSTEMCACHE ('ALL');

	DBCC FREESESSIONCACHE;

	SELECT @logical_reads = logical_reads
	FROM sys.dm_exec_requests
	WHERE session_id = @@SPID;

	SELECT @dummy = pageFill
	FROM dbo.PartitionTest
	WHERE id = @id
		AND archiveIndicator = 0;

	SELECT @logical_reads = logical_reads - @logical_reads
	FROM sys.dm_exec_requests
	WHERE session_id = @@SPID;

	UPDATE #readCount
	SET logical_reads_0 = @logical_reads
	WHERE CURRENT OF cur;

	DBCC DROPCLEANBUFFERS;

	DBCC FREEPROCCACHE;

	DBCC FREESYSTEMCACHE ('ALL');

	DBCC FREESESSIONCACHE;

	SELECT @logical_reads = logical_reads
	FROM sys.dm_exec_requests
	WHERE session_id = @@SPID;

	SELECT @dummy = pageFill
	FROM dbo.PartitionTest
	WHERE id = @id
		AND archiveIndicator = 1;

	SELECT @logical_reads = logical_reads - @logical_reads
	FROM sys.dm_exec_requests
	WHERE session_id = @@SPID;

	UPDATE #readCount
	SET logical_reads_1 = @logical_reads
	WHERE CURRENT OF cur;

	DBCC DROPCLEANBUFFERS;

	DBCC FREEPROCCACHE;

	DBCC FREESYSTEMCACHE ('ALL');

	DBCC FREESESSIONCACHE;

	SELECT @logical_reads = logical_reads
	FROM sys.dm_exec_requests
	WHERE session_id = @@SPID;

	SELECT @dummy = pageFill
	FROM dbo.PartitionTest
	WHERE id = @id;

	SELECT @logical_reads = logical_reads - @logical_reads
	FROM sys.dm_exec_requests
	WHERE session_id = @@SPID;

	UPDATE #readCount
	SET logical_reads_X = @logical_reads
	WHERE CURRENT OF cur;

	FETCH NEXT
	FROM cur
	INTO @id;
END

CLOSE cur;

DEALLOCATE cur;
GO

SELECT *
FROM #readCount;
GO

--Listing 8: Code to Recreate the PartitionTest Table with a Nonpartitioned Primary Key
DROP TABLE dbo.PartitionTest;
GO

CREATE TABLE dbo.PartitionTest (
	archiveIndicator TINYINT NOT NULL DEFAULT 0
	,id INT IDENTITY(1, 1)
	,IndexFill CHAR(888) NOT NULL DEFAULT ''
	,PageFill CHAR(7100) NOT NULL DEFAULT ''
	,CONSTRAINT PartitionTestCI UNIQUE CLUSTERED (
		id
		,archiveIndicator
		,IndexFill
		)
	,CONSTRAINT PartitionTestPK PRIMARY KEY NONCLUSTERED (id) ON \\ [PRIMARY\\]
	,
	) ON psArchive (archiveIndicator);
GO

INSERT INTO dbo.PartitionTest (archiveIndicator)
VALUES (0)
	,(1);GO 40

--Listing 9: Code to Recreate the PartitionTest Table with a Partitioned Unique Nonclustered Index
DROP TABLE dbo.PartitionTest;
GO

CREATE TABLE dbo.PartitionTest (
	archiveIndicator TINYINT NOT NULL DEFAULT 0
	,id INT IDENTITY(1, 1)
	,IndexFill CHAR(888) NOT NULL DEFAULT ''
	,PageFill CHAR(7100) NOT NULL DEFAULT ''
	,CONSTRAINT PartitionTestCI UNIQUE CLUSTERED (
		archiveIndicator
		,IndexFill
		,id
		)
	,CONSTRAINT PartitionTestI1 UNIQUE NONCLUSTERED (
		id
		,archiveIndicator
		,IndexFill
		)
	,
	) ON psArchive (archiveIndicator);
GO

INSERT INTO dbo.PartitionTest (archiveIndicator)
VALUES (0)
	,(1);
GO 40
--------------------------------------------------------------------------------------------
--https://www.mssqltips.com/sqlservertip/2888/how-to-partition-an-existing-sql-server-table/
--Table/Index creation
CREATE TABLE [dbo].[TABLE1] 
([pkcol] [int] NOT NULL,
 [datacol1] [int] NULL,
 [datacol2] [int] NULL,
 [datacol3] [varchar](50) NULL,
 [partitioncol] datetime)
GO
ALTER TABLE dbo.TABLE1 ADD CONSTRAINT PK_TABLE1 PRIMARY KEY CLUSTERED (pkcol) 
GO
CREATE NONCLUSTERED INDEX IX_TABLE1_col2col3 ON dbo.TABLE1 (datacol1,datacol2)
  WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, 
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
  ON [PRIMARY]
GO
-- Populate table data
DECLARE @val INT
SELECT @val=1
WHILE @val < 1000
BEGIN  
   INSERT INTO dbo.Table1(pkcol, datacol1, datacol2, datacol3, partitioncol) 
      VALUES (@val,@val,@val,'TEST',getdate()-@val)
   SELECT @val=@val+1
END
GO

SELECT o.name objectname,i.name indexname, partition_id, partition_number, [rows]
FROM sys.partitions p
INNER JOIN sys.objects o ON o.object_id=p.object_id
INNER JOIN sys.indexes i ON i.object_id=p.object_id and p.index_id=i.index_id
WHERE o.name LIKE '%TABLE1%'

CREATE PARTITION FUNCTION myDateRangePF (datetime)
AS RANGE RIGHT FOR VALUES ('20110101', '20120101','20130101')
GO
CREATE PARTITION SCHEME myPartitionScheme 
AS PARTITION myDateRangePF ALL TO ([PRIMARY]) 
GO
SELECT ps.name,pf.name,boundary_id,value
FROM sys.partition_schemes ps
INNER JOIN sys.partition_functions pf ON pf.function_id=ps.function_id
INNER JOIN sys.partition_range_values prf ON pf.function_id=prf.function_id

ALTER TABLE dbo.TABLE1 DROP CONSTRAINT PK_TABLE1
GO
ALTER TABLE dbo.TABLE1 ADD CONSTRAINT PK_TABLE1 PRIMARY KEY NONCLUSTERED  (pkcol)
   WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, 
         ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX IX_TABLE1_partitioncol ON dbo.TABLE1 (partitioncol)
  WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, 
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
  ON myPartitionScheme(partitioncol)
GO
-------------------------------------------------------------------------------------------
--https://www.mssqltips.com/sqlservertip/2780/archiving-sql-server-data-using-partitioning/
-- Create partition function and scheme
CREATE PARTITION FUNCTION myDateRangePF (datetime)
AS RANGE LEFT FOR VALUES ('20120401', '20120501','20120601',
                          '20120701', '20120801','20120901')
GO
CREATE PARTITION SCHEME myPartitionScheme AS PARTITION myDateRangePF ALL TO ([PRIMARY]) 
GO 
-- Create table and indexes
CREATE TABLE myPartitionTable (i INT IDENTITY (1,1),
                               s CHAR(10) , 
                               PartCol datetime NOT NULL) 
    ON myPartitionScheme (PartCol) 
GO
ALTER TABLE dbo.myPartitionTable ADD CONSTRAINT 
    PK_myPartitionTable PRIMARY KEY NONCLUSTERED (i,PartCol) 
  ON myPartitionScheme (PartCol) 
GO
CREATE CLUSTERED INDEX IX_myPartitionTable_PartCol 
  ON myPartitionTable (PartCol) 
  ON myPartitionScheme(PartCol)
GO
-- Polulate table data
DECLARE @x INT, @y INT
SELECT @y=3
WHILE @y < 10
BEGIN
 SELECT @x=1
 WHILE @x < 20000
 BEGIN  
    INSERT INTO myPartitionTable (s,PartCol) 
              VALUES ('data ' + CAST(@x AS VARCHAR),'20120' + CAST (@y AS VARCHAR)+ '15')
    SELECT @x=@x+1
 END
 SELECT @y=@y+1 
END 
GO

CREATE TABLE myPartitionTableArchive (i INT NOT NULL,
                                           s CHAR(10) , 
                                           PartCol datetime NOT NULL) 
GO
ALTER TABLE myPartitionTableArchive ADD CONSTRAINT 
    PK_myPartitionTableArchive PRIMARY KEY NONCLUSTERED (i,PartCol) 
GO
CREATE CLUSTERED INDEX IX_myPartitionTableArchive_PartCol
  ON myPartitionTableArchive (PartCol) 
GO
ALTER TABLE myPartitionTable SWITCH PARTITION 1 TO myPartitionTableArchive 
GO

sys.partition_schemes
sys.partition_functions
sys.partition_range_values

sys.partitions
sys.objects
sys.indexes
sys.filegroups

ALTER PARTITION FUNCTION myDateRangePF () MERGE RANGE ('20120401')
GO
-- Split last partition by altering partition function
-- Note: When splitting a partition you need to use the following command before issuing the 
         ALTER PARTITION command however this is not needed for the first split command issued.
--    ALTER PARTITION SCHEME myPartitionScheme NEXT USED [PRIMARY]
ALTER PARTITION FUNCTION myDateRangePF () SPLIT RANGE ('20121001')
GO
--------------------------------------------------------------------------------
--https://www.mssqltips.com/sqlservertip/1406/switching-data-in-and-out-of-a-sql-server-2005-data-partition/
CREATE PARTITION FUNCTION partRange1 (INT) 
AS RANGE LEFT FOR VALUES (10, 20, 30) ; 
GO 

-- create partition scheme 
CREATE PARTITION SCHEME partScheme1 
AS PARTITION partRange1 
ALL TO ([PRIMARY]) ; 
GO 

-- create table that uses this partitioning scheme 
CREATE TABLE partTable (col1 INT, col2 VARCHAR(20)) 
ON partScheme1 (col1) ; 
GO

-- switch in 
CREATE TABLE newPartTable (col1 INT CHECK (col1 > 30 AND col1 <= 40 AND col1 IS NOT NULL),  
col2 VARCHAR(20)) 
GO 

-- insert some sample data into new table 
INSERT INTO newPartTable (col1, col2) VALUES (31, 'newPartTable') 
INSERT INTO newPartTable (col1, col2) VALUES (32, 'newPartTable') 
INSERT INTO newPartTable (col1, col2) VALUES (33, 'newPartTable') 

-- make the switch 
ALTER TABLE newPartTable SWITCH TO partTable PARTITION 4; 
GO 

-- switch out 
CREATE TABLE nonPartTable (col1 INT, col2 VARCHAR(20)) 
ON [primary] ; 
GO 

-- make the switch 
ALTER TABLE partTable SWITCH PARTITION 1 TO nonPartTable ; 
GO 

