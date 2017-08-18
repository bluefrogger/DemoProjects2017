/*
http://weblogs.sqlteam.com/jeffs/archive/2007/10/18/sql-server-cross-apply.aspx
*/
-- Update NFLOC not needed anymore DDL
DECLARE @DirtyData AS TABLE(
	Id INT
	, Data NVARCHAR(128)
)

DECLARE @CharTally AS TABLE(
	Id INT
	, CharSymbol CHAR(1)
)

DECLARE @Tally AS TABLE(
	Num INT
)
-- DML
;WITH chartable AS
(
	SELECT 0 as Id, CHAR(0) AS CharSymbol
	UNION ALL
	SELECT Id + 1, CHAR(Id + 1)
	FROM chartable
	WHERE Id < 255
)
INSERT @CharTally (Id, CharSymbol)
SELECT Id, CharSymbol 
FROM chartable
OPTION (MAXRECURSION 255)

INSERT @Tally (Num)
SELECT TOP (255) ROW_NUMBER() OVER (ORDER BY (SELECT null)) FROM sys.columns

INSERT @DirtyData
VALUES (1, 'd00msday')
	,(2, '1day1thousand')
	,(3, 'howmany3')
	,(4, 'springs34')


;with CleanData AS(
	SELECT xaDir.Id, tal.Num, xaDir.CharCurrent
	FROM @Tally AS tal
	CROSS APPLY (
		SELECT dir.Id
			, tal.Num
			, SUBSTRING(dir.Data, tal.Num, 1) AS CharCurrent
        FROM @DirtyData AS dir
		WHERE tal.Num <= LEN(dir.Data)
	) AS xaDir
	WHERE PATINDEX('%[a-z]%', xaDir.CharCurrent) > 0
)
SELECT dir.Data
	, xx.CharCurrent--.value('.', 'nvarchar(1000)') AS CleanData
FROM @DirtyData as dir
CROSS APPLY (
	SELECT cle.CharCurrent AS [text()]
	FROM CleanData AS cle
	WHERE cle.id = dir.id
	ORDER BY cle.Num
	FOR XML PATH('')--, TYPE
) AS xx(CharCurrent)

