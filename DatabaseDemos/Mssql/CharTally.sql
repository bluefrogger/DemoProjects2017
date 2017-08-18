
;WITH chartable
AS(
	SELECT 0 N, CHAR(0) [Char]
	UNION ALL
	SELECT N + 1, CHAR(N + 1)
	FROM chartable
	WHERE N < 255
)
SELECT * FROM chartable OPTION (maxrecursion 255)
