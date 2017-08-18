--select * from [SalesLT].[SalesOrderDetail]
--select * from [SalesLT].[SalesOrderHeader]

SELECT soh.SalesOrderId
	 , soh.OrderDate
	 ,
	(
		SELECT MAX(sod.UnitPrice)
		FROM SalesLT.SalesOrderDetail AS sod
		WHERE sod.SalesOrderID = soh.SalesOrderID
	) AS MaxUnitPrice
FROM SalesLT.SalesOrderHeader AS soh;


SELECT soh.SalesOrderId
	 , soh.OrderDate
	 , sod.MaxUnitPrice
FROM SalesLT.SalesOrderHeader AS soh
JOIN
(
	SELECT SalesOrderID
		 , MAX(UnitPrice) AS MaxUnitPrice
	FROM SalesLT.SalesOrderDetail AS sod
	GROUP BY SalesOrderID
) AS sod
	 ON soh.SalesOrderID = sod.SalesOrderID;

	 
SELECT soh.SalesOrderId
	 , soh.OrderDate
	 , sod.MaxUnitPrice
FROM SalesLT.SalesOrderHeader AS soh
CROSS APPLY
(
	SELECT MAX(UnitPrice) AS MaxUnitPrice
	FROM SalesLT.SalesOrderDetail AS sod
	WHERE sod.SalesOrderID = soh.SalesOrderID
) AS sod;

/*
	Unlike correlated sub-queries, CROSS APPLY works with multiple rows. CROSS APPLY can return multiple columns.
*/


DECLARE @BigNumbers AS TABLE(
	Id int
)
DECLARE @SmallNumbers AS TABLE(
	Id int
)
INSERT @BigNumbers (Id)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
FROM sys.tables

INSERT @SmallNumbers (Id)
SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
FROM sys.servers

SELECT bn.Id, sn.Id
FROM @BigNumbers AS bn
CROSS JOIN @SmallNumbers AS sn
WHERE bn.Id = sn.Id

SELECT bn.Id, xsn.Id
FROM @BigNumbers AS bn
CROSS APPLY(
	SELECT sn.Id
    FROM @SmallNumbers AS sn
	WHERE sn.Id = bn.Id
) AS xsn(Id)