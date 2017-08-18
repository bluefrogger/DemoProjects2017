
/*
SELECT * FROM [dbo].[LogCalendar]
TRUNCATE TABLE dbo.LogCalendar
*/

INSERT dbo.LogCalendar (AddressModifiedDate)
SELECT DISTINCT ModifiedDate
FROM awlt2011.saleslt.Address
WHERE NOT EXISTS(
	SELECT AddressModifiedDate
	FROM dbo.LogCalendar AS lc
)


UPDATE olc
SET ServerName = 'AlexY10'
	,DatabaseName = 'AWLT2011'
	,SchemaName = 'SalesLt'
	,TableName = 'Address'
	,SBMessage = (
	SELECT Handle
		, ISNULL(ServerName, 'AlexY10') AS ServerName
		, ISNULL(DatabaseName, 'AWLT2011') AS DatabaseName
		, ISNULL(SchemaName, 'SalesLt') AS SchemaName
		, ISNULL(TableName, 'Address') AS TableName
		, AddressModifiedDate
	FROM dbo.LogCalendar AS ilc
	WHERE ilc.id = olc.id
	FOR XML PATH('ExtractRequest')
	)
FROM dbo.LogCalendar olc
WHERE ExtractDate IS null


--DECLARE @LogCalendar AS TABLE 
--(Id INT
--,Handle UNIQUEIDENTIFIER NULL DEFAULT (NEWID())
--,ServerName sysname NULL
--,DatabaseName sysname NULL
--,SchemaName sysname NULL
--,TableName sysname NULL
--,AddressModifiedDate DATE NULL
--,StageDate DATE NULL
--,LogStatus INT NULL DEFAULT ((0))
--,LogRowCount BIGINT NULL); 


--SELECT
--	ServerName = 'AlexY10'
--	,DatabaseName = 'AWLT2011'
--	,SchemaName = 'SalesLt'
--	,TableName = 'Address'
--	,SBMessage = (
--	SELECT Handle, ISNULL(ServerName, 'AlexY10') AS a
--		, ISNULL(DatabaseName, 'AWLT2011') AS b
--		, ISNULL(SchemaName, 'SalesLt') AS c
--		, ISNULL(TableName, 'Address') AS d
--		, AddressModifiedDate
--	FROM dbo.LogCalendar AS ilc
--	WHERE ilc.id = olc.id
--	FOR XML PATH('ExtractRequest')
--	)
--FROM dbo.LogCalendar olc
--WHERE ExtractDate IS null
