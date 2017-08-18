create table dbo.SourceTables(
	Id int identity(1,1)
	, SchemaName sysname
	, TableName sysname
	, GroupId int
	, Detail nvarchar(512)
)
