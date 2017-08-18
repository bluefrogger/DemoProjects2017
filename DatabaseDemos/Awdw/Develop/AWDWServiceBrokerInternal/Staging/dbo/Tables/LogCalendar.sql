create table dbo.LogCalendar(
	Id int identity(1,1)
	, Handle uniqueidentifier constraint df_LogCalendar_Handle default (newid())
	, ServerName sysname
	, DatabaseName sysname
	, SchemaName sysname
	, TableName sysname
	, AddressModifiedDate date
	, ExtractDate date
	, LogStatus int constraint df_LogCalendar_LogStatus default (0)
	, LogRowCount BIGINT
    , SBMessage xml
)
