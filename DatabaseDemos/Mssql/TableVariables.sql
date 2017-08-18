http://stackoverflow.com/questions/886050/creating-an-index-on-a-table-variable

DECLARE @tab TABLE (
	id INT IDENTITY(1,1)
	,life NVARCHAR(20) INDEX ci_tab_life clustered
)

DECLARE @tab2 TABLE (
	id INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED
	,life NVARCHAR(20) UNIQUE CLUSTERED
)

