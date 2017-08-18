
DBCC show_statistics ('Sales.SalesOrder','ix_SalesOrderHeader_CustomerID')

select * from sys.stats
	WHERE object_id = object_id('Sales.SalesOrderHeader')
select * from sys.dm_db_stats_properties(object_id('Sales.SalesOrderHeader'),5)

update statistics
sp_updatestats
