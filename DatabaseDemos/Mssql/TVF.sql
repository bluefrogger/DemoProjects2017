DROP FUNCTION dev.udfSelect1
GO

CREATE FUNCTION dev.udfSelect1()
RETURNs table
AS RETURN (
	SELECT 1 AS cro FROM sys.tables
)
GO

CREATE TABLE #test(
	id INT
)

INSERT #test(id)
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM sys.tables

SELECT *
FROM #test AS t
CROSS join dev.udfSelect1()

