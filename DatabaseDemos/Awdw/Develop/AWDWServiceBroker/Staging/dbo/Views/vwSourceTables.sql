create view dbo.vwSourceTables
as
select tab.Id, tab.SchemaName, tab.TableName, grp.GroupName, grp.Frequency
from dbo.SourceTables as tab
join dbo.SourceGroups as grp
	on tab.GroupId = grp.Id
go
