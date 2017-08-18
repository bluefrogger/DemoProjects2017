/*
http://stackoverflow.com/questions/30861919/what-is-rows-unbounded-preceding-used-for-in-teradata
https://sqlwithmanoj.com/tag/unbounded-preceding/
*/

It's the "frame" or "range" clause of window functions, which are part of the SQL standard and implemented in many databases, including Teradata.

A simple example would be to calculate the average amount in a frame of three days. I'm using PostgreSQL syntax for the example, but it will be the same for Teradata:

WITH data (t, a) AS (
  VALUES(1, 1),
        (2, 5),
        (3, 3),
        (4, 5),
        (5, 4),
        (6, 11)
)
SELECT t, a, avg(a) OVER (ORDER BY t ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
FROM data
ORDER BY t
... which yields:

t  a  avg
----------
1  1  3.00
2  5  3.00
3  3  4.33
4  5  4.00
5  4  6.67
6 11  7.50
As you can see, each average is calculated "over" an ordered frame consisting of the range between the previous row (1 preceding) and the subsequent row (1 following).

When you write ROWS UNBOUNDED PRECEDING, then the frame's lower bound is simply infinite. This is useful when calculating sums (i.e. "running totals"), for instance:

WITH data (t, a) AS (
  VALUES(1, 1),
        (2, 5),
        (3, 3),
        (4, 5),
        (5, 4),
        (6, 11)
)
SELECT t, a, sum(a) OVER (ORDER BY t ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM data
ORDER BY t
yielding...

t  a  sum
---------
1  1    1
2  5    6
3  3    9
4  5   14
5  4   18
6 11   29
Here's another very good explanations of SQL window functions.

SELECT TOP (1) WITH TIES AppointmentID, AppointmentResourceID 
		FROM SHSQL1.[coredev.solutahealth.com].dbo.sa_AppointmentResources
		ORDER BY ROW_NUMBER() OVER (PARTITION BY AppointmentID ORDER BY AppointmentResourceID)