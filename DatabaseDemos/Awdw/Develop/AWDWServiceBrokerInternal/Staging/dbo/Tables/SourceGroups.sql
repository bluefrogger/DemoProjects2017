create table dbo.SourceGroups(
	Id int identity(1,1)
	, GroupName sysname
	, Frequency nvarchar(128)
	, Detail nvarchar(512)
)
