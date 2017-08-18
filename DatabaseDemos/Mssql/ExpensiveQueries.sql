/*
http://stackoverflow.com/questions/28952/cpu-utilization-by-database
https://www.brentozar.com/responder/log-sp_whoisactive-to-a-table/
*/

SELECT total_worker_time/execution_count AS AvgCPU  
, total_worker_time AS TotalCPU
, total_elapsed_time/execution_count AS AvgDuration  
, total_elapsed_time AS TotalDuration  
, (total_logical_reads+total_physical_reads)/execution_count AS AvgReads 
, (total_logical_reads+total_physical_reads) AS TotalReads
, execution_count   
, SUBSTRING(st.TEXT, (qs.statement_start_offset/2)+1  
, ((CASE qs.statement_end_offset  WHEN -1 THEN datalength(st.TEXT)  
ELSE qs.statement_end_offset  
END - qs.statement_start_offset)/2) + 1) AS txt  
, query_plan
FROM sys.dm_exec_query_stats AS qs  
cross apply sys.dm_exec_sql_text(qs.sql_handle) AS st  
cross apply sys.dm_exec_query_plan (qs.plan_handle) AS qp 
ORDER BY 1 DESC

/*
https://social.msdn.microsoft.com/Forums/sqlserver/en-US/9802159d-518c-4e7d-bef9-ae6debdd57f7/high-memory-usage-by-sql-server-and-very-slow?forum=transactsql
http://stackoverflow.com/questions/32770898/how-can-i-troubleshoot-performance-issues-in-sql-server/32770965
*/

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

/*
https://social.msdn.microsoft.com/Forums/sqlserver/en-US/28baad66-4b7c-4308-b157-72d97a1a2a12/keeping-track-of-cpu-utilization-history-using-date?forum=sqldatabaseengine
http://stackoverflow.com/questions/6370855/determining-which-sql-server-database-is-spiking-the-cpu
*/

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



CREATE TABLE temp_sp_who2
    (
      SPID INT,
      Status VARCHAR(1000) NULL,
      Login SYSNAME NULL,
      HostName SYSNAME NULL,
      BlkBy SYSNAME NULL,
      DBName SYSNAME NULL,
      Command VARCHAR(1000) NULL,
      CPUTime INT NULL,
      DiskIO INT NULL,
      LastBatch VARCHAR(1000) NULL,
      ProgramName VARCHAR(1000) NULL,
      SPID2 INT
      , rEQUESTID INT NULL --comment out for SQL 2000 databases

    )


INSERT  INTO temp_sp_who2
EXEC sp_who2

SELECT  *
FROM    temp_sp_who2
WHERE   DBName = 'yourDb'


Finding these can be a real pain if you are not familiar with SQL Server’s system tables that are tracking all this information for you. However, hopefully by exploring some of the queries that I have listed below (for the most common problems), you will find some insight into your particular issue.

What it does: Lists the top statements by average input/output usage for the current database

SELECT TOP(50) OBJECT_NAME(qt.objectid) AS [SP Name],
(qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count AS [Avg IO],
SUBSTRING(qt.[text],qs.statement_start_offset/2, 
               (CASE 
                              WHEN qs.statement_end_offset = -1 
                THEN LEN(CONVERT(nvarchar(max), qt.[text])) * 2 
                              ELSE qs.statement_end_offset 
                END - qs.statement_start_offset)/2) AS [Query Text]         
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.[dbid] = DB_ID()
ORDER BY [Avg IO] DESC OPTION (RECOMPILE);
Notes for how to use: Helps you find the most expensive statements for I/O by SP

What it does: Possible Bad NC Indexes (writes > reads)

SELECT OBJECT_NAME(s.[object_id]) AS [Table Name], i.name AS [Index Name], i.index_id,
user_updates AS [Total Writes], user_seeks + user_scans + user_lookups AS [Total Reads],
user_updates - (user_seeks + user_scans + user_lookups) AS [Difference]
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON s.[object_id] = i.[object_id]
AND i.index_id = s.index_id
WHERE OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
AND s.database_id = DB_ID()
AND user_updates > (user_seeks + user_scans + user_lookups)
AND i.index_id > 1
ORDER BY [Difference] DESC, [Total Writes] DESC, [Total Reads] ASC OPTION (RECOMPILE);
Notes for how to use: — Look for indexes with high numbers of writes and zero or very low numbers of reads — Consider your complete workload — Investigate further before dropping an index

What it does: Missing Indexes current database by Index Advantage

SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [index_advantage], 
migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID() -- Remove this to see for entire instance
ORDER BY index_advantage DESC OPTION (RECOMPILE);
Notes on how to use: — Look at last user seek time, number of user seeks to help determine source and importance — SQL Server is overly eager to add included columns, so beware — Do not just blindly add indexes that show up from this query!!!

What it does: Get fragmentation info for all indexes above a certain size in the current database — Note: This could take some time on a very large database

SELECT DB_NAME(database_id) AS [Database Name], OBJECT_NAME(ps.OBJECT_ID) AS [Object Name], 
i.name AS [Index Name], ps.index_id, index_type_desc,
avg_fragmentation_in_percent, fragment_count, page_count
FROM sys.dm_db_index_physical_stats( NULL,NULL, NULL, NULL ,'LIMITED') AS ps
INNER JOIN sys.indexes AS i 
ON ps.[object_id] = i.[object_id] 
AND ps.index_id = i.index_id
WHERE database_id = DB_ID()
--AND page_count > 500
ORDER BY avg_fragmentation_in_percent DESC OPTION (RECOMPILE);
Notes on how to use: — Helps determine whether you have fragmentation in your relational indexes — and how effective your index maintenance strategy is

These should get you started!

I wrote a longer blog post about this topic here for those interested.