/*
http://michaeljswart.com/2009/08/get-rid-of-rid-lookups/

--Each table should have a clustered index (of course there are exceptions but we’re dealing with rules-of-thumb here).
--A non-clustered index has been created indicating that someone somewhere 
	identified an ordering on one or more columns that made sense for that data.
--There is at least one query (i.e. the one that generated the RID Lookup) 
	that needs columns that are not covered by the non-clustered index.
http://sqlblog.com/blogs/aaron_bertrand/archive/2010/02/08/bad-habits-to-kick-putting-an-identity-column-on-every-table.aspx
*/
GO

EXEC sp_helpindex 'dbo.[Wf_WorkFlowInstances]'
SELECT DISTINCT
        [T].[name] 'Table Name'
       ,[I].[name] 'Index Name'
       ,[I].[type_desc] 'Index Type'
       ,[C].[name] 'Included Column Name'
FROM    [sys].[indexes] [I]
        INNER JOIN [sys].[index_columns] [IC] ON [I].[object_id] = [IC].[object_id]
                                                 AND [I].[index_id] = [IC].[index_id]
        INNER JOIN [sys].[columns] [C] ON [IC].[object_id] = [C].[object_id]
                                          AND [IC].[column_id] = [C].[column_id]
        INNER JOIN [sys].[tables] [T] ON [I].[object_id] = [T].[object_id]
WHERE   [IC].[is_included_column] = 1
ORDER BY [T].[name]
       ,[I].[name];
GO

/*
case vs where
http://weblogs.sqlteam.com/jeffs/archive/2003/11/14/513.aspx
parameter sniffing
http://use-the-index-luke.com/sql/where-clause/bind-parameters
tuning
https://medium.com/@erickmendonca/basic-tips-on-tuning-sql-server-queries-f834f09bafaf#.x94zr5uq7
*/
--https://www.brentozar.com/blitzcache/long-running-queries/
SELECT  st.text,
        qp.query_plan,
        qs.*
FROM    (
    SELECT  TOP 50 *
    FROM    sys.dm_exec_query_stats
    ORDER BY total_worker_time DESC
) AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE qs.max_worker_time > 300
      OR qs.max_elapsed_time > 300

--http://blog.sqlauthority.com/2009/01/02/sql-server-2008-2005-find-longest-running-query-tsql/
DBCC FREEPROCCACHE
--Run following query to find longest running query using T-SQL.

SELECT DISTINCT TOP 10
        t.text QueryName
       ,s.execution_count AS ExecutionCount
       ,s.max_elapsed_time AS MaxElapsedTime
       ,ISNULL(s.total_elapsed_time / s.execution_count, 0) AS AvgElapsedTime
       ,s.creation_time AS LogCreatedOn
       ,ISNULL(s.execution_count / DATEDIFF(s, s.creation_time, GETDATE()), 0) AS FrequencyPerSec
FROM    sys.dm_exec_query_stats s
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) t
ORDER BY s.max_elapsed_time DESC;
GO

--http://stackoverflow.com/questions/32770898/how-can-i-troubleshoot-performance-issues-in-sql-server/32770965
SELECT TOP(50) OBJECT_NAME(qt.objectid) AS [SP Name],
(qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count AS [Avg IO],
SUBSTRING(qt.[text],qs.statement_start_offset/2, 
      (CASE 
            WHEN qs.statement_end_offset = -1 
       THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
            ELSE qs.statement_end_offset 
       END - qs.statement_start_offset)/2) AS [Query Text]  
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.[dbid] = DB_ID()
ORDER BY [Avg IO] DESC OPTION (RECOMPILE);

--https://social.msdn.microsoft.com/Forums/sqlserver/en-US/28baad66-4b7c-4308-b157-72d97a1a2a12/keeping-track-of-cpu-utilization-history-using-date?forum=sqldatabaseengine
WITH DB_CPU_Stats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms]
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID] 
              FROM sys.dm_exec_plan_attributes(qs.plan_handle)
              WHERE attribute = N'dbid') AS F_DB
GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
       DatabaseName, [CPU_Time_Ms], 
       CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num OPTION (RECOMPILE);

WITH DB_CPU_Stats
AS (
	SELECT DatabaseID
		,DB_Name(DatabaseID) AS [DatabaseName]
		,SUM(total_worker_time) AS [CPU_Time_Ms]
		,CONVERT([smalldatetime], GETDATE()) AS [CPU_Stats_DateTime]
	FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
	CROSS APPLY (
		SELECT CONVERT(INT, value) AS [DatabaseID]
		FROM sys.dm_exec_plan_attributes(qs.plan_handle)
		WHERE attribute = N'dbid'
		) AS F_DB
	GROUP BY DatabaseID
	)
SELECT ROW_NUMBER() OVER (
		ORDER BY [CPU_Time_Ms] DESC
		) AS [row_num]
	,DatabaseName
	,[CPU_Time_Ms]
	,CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER () * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
	,[CPU_Stats_DateTime]
FROM DB_CPU_Stats
WHERE DatabaseID > 4 -- system databases
	AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num
OPTION (RECOMPILE);