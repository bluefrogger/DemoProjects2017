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