merge dbo.SourceTables as tar
using (values
	(1, 'SalesLT', 'Address', 2, '')
	, (2, 'SalesLT', 'Customer', 2, '')
	, (3, 'SalesLT', 'CustomerAddress', 2, '')
	, (4, 'SalesLT', 'Product', 3, '')
	, (5, 'SalesLT', 'ProductCategory', 3, '')
	, (6, 'SalesLT', 'ProductDescription', 3, '')
	, (7, 'SalesLT', 'ProductModel', 3, '')
	, (8, 'SalesLT', 'ProductModelProductDescription', 2, '')
	, (9, 'SalesLT', 'SalesOrderDetail', 1, '')
	, (10, 'SalesLT', 'SalesOrderHeader', 1, '')
) as src (Id, SchemaName, TableName, GroupId, Detail)
on tar.Id = src.Id
when not matched by target then
insert (Id, SchemaName, TableName, GroupId, Detail)
values (src.Id, src.SchemaName, src.TableName, src.GroupId, src.Detail);

merge dbo.SourceGroups as tar
using (values
	(1, 'Transactional', 'Daily', '')
	, (2, 'Lookup', 'Daily', 'Volatile')
	, (3, 'Lookup', 'Monthly', 'Stable')
) as src(Id, GroupName, Frequency, Detail)
on tar.Id = src.Id
when not matched by target then
insert (Id, GroupName, Frequency, Detail)
values (src.Id, src.GroupName, src.Frequency, src.Detail);
go
