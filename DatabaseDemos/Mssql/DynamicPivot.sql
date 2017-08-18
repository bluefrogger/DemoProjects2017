/*
http://stackoverflow.com/questions/10404348/sql-server-dynamic-pivot-query
*/

CREATE table temp
(
    date datetime,
    category varchar(3),
    amount money
)

insert into temp values ('1/1/2012', 'ABC', 1000.00)
insert into temp values ('2/1/2012', 'DEF', 500.00)
insert into temp values ('2/1/2012', 'GHI', 800.00)
insert into temp values ('2/10/2012', 'DEF', 700.00)
insert into temp values ('3/1/2012', 'ABC', 1100.00)


DECLARE @cols AS NVARCHAR(MAX),
    @query  AS NVARCHAR(MAX);

SET @cols = STUFF((SELECT distinct ',' + QUOTENAME(c.category) 
            FROM temp c
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'')

set @query = 'SELECT date, ' + @cols + ' from 
            (
                select date
                    , amount
                    , category
                from temp
           ) x
            pivot 
            (
                 max(amount)
                for category in (' + @cols + ')
            ) p '


execute(@query)

drop table temp
/*
http://sqlmag.com/t-sql/pivoting-dynamic-way
*/
DECLARE @sql AS VARCHAR(8000)
DECLARE @col AS VARCHAR(8000)

SELECT @col = COALESCE(@col + ',', '') + QUOTENAME(c.category)
	FROM (
		SELECT DISTINCT category
		FROM temp
		) AS c
		ORDER BY c.category

SET @sql = '
with PivotData as (
	select date
		, amount
		, category
	from temp
)
select date, '
+ @col + '
FROM PivotData
PIVOT (
	max(amount)
	for category in (' + @col + ')
) as piv
'
PRINT @sql

EXEC(@sql)

/*
https://www.mssqltips.com/sqlservertip/2783/script-to-create-dynamic-pivot-queries-in-sql-server/
*/
USE tempdb;
GO
CREATE TABLE dbo.Products
(
  ProductID INT PRIMARY KEY,
  Name      NVARCHAR(255) NOT NULL UNIQUE
  /* other columns */
);
INSERT dbo.Products VALUES
(1, N'foo'),
(2, N'bar'),
(3, N'kin');
CREATE TABLE dbo.OrderDetails
(
  OrderID INT,
  ProductID INT NOT NULL
    FOREIGN KEY REFERENCES dbo.Products(ProductID),
  Quantity INT
  /* other columns */
);
INSERT dbo.OrderDetails VALUES
(1, 1, 1),
(1, 2, 2),
(2, 1, 1),
(3, 3, 1);

SELECT p.Name, Quantity = SUM(o.Quantity)
  FROM dbo.Products AS p
  INNER JOIN dbo.OrderDetails AS o
  ON p.ProductID = o.ProductID
  GROUP BY p.Name;

SELECT p.[foo], p.[bar], p.[kin]
FROM
(
  SELECT p.Name, o.Quantity
   FROM dbo.Products AS p
   INNER JOIN dbo.OrderDetails AS o
   ON p.ProductID = o.ProductID
) AS j
PIVOT
(
  SUM(Quantity) FOR Name IN ([foo],[bar],[kin])
) AS p;

INSERT dbo.Products SELECT 4, N'blat';
INSERT dbo.OrderDetails SELECT 4,4,5;

DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
SET @columns = N'';
SELECT @columns += N', p.' + QUOTENAME(Name)
  FROM (SELECT p.Name FROM dbo.Products AS p
  INNER JOIN dbo.OrderDetails AS o
  ON p.ProductID = o.ProductID
  GROUP BY p.Name) AS x;
SET @sql = N'
	SELECT ' + STUFF(@columns, 1, 2, '') + '
	FROM
	(
	  SELECT p.Name, o.Quantity
	   FROM dbo.Products AS p
	   INNER JOIN dbo.OrderDetails AS o
	   ON p.ProductID = o.ProductID
	) AS j
	PIVOT
	(
	  SUM(Quantity) FOR Name IN ('
	  + STUFF(REPLACE(@columns, ', p.[', ',['), 1, 1, '')
	  + ')
	) AS p;';
PRINT @sql;
EXEC sp_executesql @sql;

SELECT p.[foo], p.[bar], p.[kin], p.[blat]
FROM
(
  SELECT p.Name, o.Quantity
   FROM dbo.Products AS p
   INNER JOIN dbo.OrderDetails AS o
   ON p.ProductID = o.ProductID
) AS j
PIVOT
(
  SUM(Quantity) FOR Name IN ([foo],[bar],[kin],[blat])
) AS p;

