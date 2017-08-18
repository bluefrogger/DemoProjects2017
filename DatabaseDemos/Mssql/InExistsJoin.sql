/*
http://weblogs.sqlteam.com/mladenp/archive/2007/05/18/60210.aspx
*/

CREATE TABLE t1 (id INT, title VARCHAR(20), someIntCol INT)
GO
CREATE TABLE t2 (id INT, t1Id INT, someData VARCHAR(20))
GO

INSERT INTO t1
SELECT 1, 'title 1', 5 UNION ALL
SELECT 2, 'title 2', 5 UNION ALL
SELECT 3, 'title 3', 5 UNION ALL
SELECT 4, 'title 4', 5 UNION ALL
SELECT null, 'title 5', 5 UNION ALL
SELECT null, 'title 6', 5

INSERT INTO t2
SELECT 1, 1, 'data 1' UNION ALL
SELECT 2, 1, 'data 2' UNION ALL
SELECT 3, 2, 'data 3' UNION ALL
SELECT 4, 3, 'data 4' UNION ALL
SELECT 5, 3, 'data 5' UNION ALL
SELECT 6, 3, 'data 6' UNION ALL
SELECT 7, 4, 'data 7' UNION ALL
SELECT 8, null, 'data 8' UNION ALL
SELECT 9, 6, 'data 9' UNION ALL
SELECT 10, 6, 'data 10' UNION ALL
SELECT 11, 8, 'data 11'

SELECT * FROM dbo.t1 AS ts
SELECT * FROM dbo.t2 AS t
------------------------------------------------------------------
-- we want to get all data in t1 that has a child row in t2
------------------------------------------------------------------

-- join gives us more rows than we need, because it joins to every child row
SELECT    t1.* 
FROM    t1 
        JOIN t2 ON t1.id = t2.t1Id
-- distinct would solve that but it's not pretty nor efficient
SELECT    DISTINCT t1.* 
FROM    t1 
        JOIN t2 ON t1.id = t2.t1Id

-- now this is a weird part where someIntCol is a column in t1 
-- but the parser doesn't seem to mind that
SELECT    t1.* 
FROM    t1 
WHERE    t1.id IN (SELECT someIntCol FROM t2)

-- here in and exists both get correct results
SELECT    t1.* 
FROM    t1 
WHERE    t1.id IN (SELECT t1id FROM t2)

SELECT    t1.* 
FROM    t1 
WHERE    exists (SELECT * FROM t2 WHERE t1.id = t2.t1id)

------------------------------------------------------------------
-- we want to get all data in t1 that doesn't have a child row in t2
------------------------------------------------------------------

-- join gives us the correct result
SELECT    t1.* 
FROM    t1 
        LEFT JOIN t2 ON t1.id = t2.t1Id
WHERE    t2.id IS NULL

-- IN doesn't get correct results.
-- That's because of how IN treats NULLs and the Three-valued logic
-- NULL is treated as an unknown, so if there's a null in the t2.t1id 
-- NOT IN will return either NOT TRUE or NOT UNKNOWN. And neither can be TRUE.
-- when there's a NULL in the t1id column of the t2 table the NOT IN query will always return an empty set. 
SELECT    t1.* 
FROM    t1 
WHERE    t1.id NOT IN (SELECT t1id FROM t2)

-- NOT EXISTS gets correct results
SELECT    t1.* 
FROM    t1 
WHERE    NOT EXISTS (SELECT * FROM t2 WHERE t1.id = t2.t1id)
GO

DROP TABLE t2
DROP TABLE t1