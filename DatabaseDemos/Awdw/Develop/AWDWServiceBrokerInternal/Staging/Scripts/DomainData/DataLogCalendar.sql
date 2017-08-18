
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
	FOR XML PATH('ExtractMessage')
	)
FROM dbo.LogCalendar olc
WHERE ExtractDate IS null

