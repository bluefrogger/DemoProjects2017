
CREATE NONCLUSTERED INDEX nci_SalesOrderHeader_Status
ON [Sales].[SalesOrderHeader] ([Status])

/*
https://technet.microsoft.com/en-us/library/ms179325%28v=sql.105%29.aspx?f=255&MSPPError=-2147217396
Before you create nonclustered indexes, you should understand how your data will be accessed. 
Consider using a nonclustered index for queries that have the following attributes:

Use JOIN or GROUP BY clauses.
Create multiple nonclustered indexes on columns involved in join and grouping operations
	, and a clustered index on any foreign key columns.

Queries that do not return large result sets.

Create filtered indexes to cover queries that return a well-defined subset of rows from a large table.

Contain columns frequently involved in search conditions of a query, such as WHERE clause, that return exact matches.

https://technet.microsoft.com/en-us/library/jj835095(v=sql.110).aspx
https://sqlperformance.com/2012/11/t-sql-queries/benefits-indexing-foreign-keys

The selection of the right indexes for a database and its workload is a complex balancing act between query speed and update cost.

Create nonclustered indexes on the columns that are frequently used in predicates and join conditions in queries. 
However, you should avoid adding unnecessary columns. 
Adding too many index columns can adversely affect disk space and index maintenance performance.

Consider the order of the columns if the index will contain multiple columns. 
The column that is used in the WHERE clause in an equal to (=), greater than (>), less than (<), or BETWEEN search condition, 
or participates in a join, should be placed first. 
Additional columns should be ordered based on their level of distinctness, that is, from the most distinct to the least distinct.
*/

--CLUSTERED
/*
Before you create clustered indexes, understand how your data will be accessed. Consider using a clustered index for queries that do the following:
Return a range of values by using operators such as BETWEEN, >, >=, <, and <=.
After the row with the first value is found by using the clustered index, rows with subsequent indexed values are guaranteed to be physically adjacent. For example, if a query retrieves records between a range of sales order numbers, a clustered index on the column SalesOrderNumber can quickly locate the row that contains the starting sales order number, and then retrieve all successive rows in the table until the last sales order number is reached.
Return large result sets.
Use JOIN clauses; typically these are foreign key columns.
Use ORDER BY, or GROUP BY clauses.
An index on the columns specified in the ORDER BY or GROUP BY clause may remove the need for the Database Engine to sort the data, because the rows are already sorted. This improves query performance.

Are unique or contain many distinct values
For example, an employee ID uniquely identifies employees. A clustered index or PRIMARY KEY constraint on the EmployeeID column would improve the performance of queries that search for employee information based on the employee ID number. Alternatively, a clustered index could be created on LastName, FirstName, MiddleName because employee records are frequently grouped and queried in this way, and the combination of these columns would still provide a high degree of difference.
Are accessed sequentially
For example, a product ID uniquely identifies products in the Production.Product table in the AdventureWorks2012 database. Queries in which a sequential search is specified, such as WHERE ProductID BETWEEN 980 and 999, would benefit from a clustered index on ProductID. This is because the rows would be stored in sorted order on that key column.
Defined as IDENTITY.
Used frequently to sort the data retrieved from a table.
It can be a good idea to cluster, that is physically sort, the table on that column to save the cost of a sort operation every time the column is queried.
*/

--NONCLUSTERED
/*

*/