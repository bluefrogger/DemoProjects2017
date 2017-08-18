USE AW2014

SELECT FirstName
	, LEAD(FirstName) OVER (ORDER BY BusinessEntityID)
	, LAG(FirstName) OVER (ORDER BY BusinessEntityID)
FROM [Person].[Person]


SELECT TOP(1000) sod.SalesOrderDetailID
	, sod.SalesOrderID
	, sod.UnitPrice
	, SUM(sod.UnitPrice) OVER (PARTITION BY sod.SalesOrderID 
		ORDER BY sod.SalesOrderDetailID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM Sales.SalesOrderDetail AS sod

