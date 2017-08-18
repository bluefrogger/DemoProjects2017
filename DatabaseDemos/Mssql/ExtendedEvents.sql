/*
http://blog.sqlauthority.com/2016/06/22/sql-server-sql-profiler-vs-extended-events/
*/

SELECT
      wait_type
    , wait_time = wait_time_ms / 1000.
    , wait_resource = (wait_time_ms - signal_wait_time_ms) / 1000.
    , wait_signal = signal_wait_time_ms / 1000.
    , waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE [wait_type] IN (
        'TRACEWRITE', 'OLEDB', 'SQLTRACE_LOCK',
        'SQLTRACE_FILE_BUFFER', 'SQLTRACE_FILE_WRITE_IO_COMPLETION'
    )

DECLARE @id INT
 
EXEC sys.sp_trace_create @id OUTPUT, 2, N'D:\MyTrace'
 
EXEC sys.sp_trace_setevent @id, 10, 1, 1
EXEC sys.sp_trace_setevent @id, 10, 13, 1
EXEC sys.sp_trace_setevent @id, 10, 15, 1
EXEC sys.sp_trace_setevent @id, 12, 1, 1
EXEC sys.sp_trace_setevent @id, 12, 10, 1
EXEC sys.sp_trace_setevent @id, 12, 13, 1
EXEC sys.sp_trace_setevent @id, 12, 15, 1

SELECT
      EventCategory = c.Name
    , EventClass = e.Name
    , EventColumn = t.Name
    , EventID = e.trace_event_id
    , ColumnID = b.trace_column_id
FROM sys.trace_categories c
JOIN sys.trace_events e ON e.category_id = c.category_id
JOIN sys.trace_event_bindings b ON b.trace_event_id = e.trace_event_id
JOIN sys.trace_columns t ON t.trace_column_id = b.trace_column_id
--WHERE b.trace_event_id IN (10, 12)

--Then, we can filter information that will be traced. For instance, let’s ignore queries sent by SQL Profiler:
EXEC sys.sp_trace_setfilter @id, 10, 1, 7, N'SQL Profiler'
--After all settings, we can run the trace:
EXEC sys.sp_trace_setstatus @id, 1

--To enable SQL Profiler to output trace results, we need to execute a query similar to the following:
SELECT SPID, TextData, ApplicationName, Duration = Duration / 1000, EndTime
FROM (
    SELECT TOP(1) [path]
    FROM sys.traces
    WHERE [path] LIKE N'D:\MyTrace%'
) t
CROSS APPLY sys.fn_trace_gettable(t.[path], DEFAULT)

--When tracing is no longer required, we can stop and delete it:
DECLARE @id INT = (
    SELECT TOP(1) id
    FROM sys.traces
    WHERE [path] LIKE N'D:\MyTrace%'
)
 
EXEC sys.sp_trace_setstatus @id, 0
EXEC sys.sp_trace_setstatus @id, 2
/*
	The same principle is used in Extended Events. First, the event should be created:
*/
CREATE EVENT SESSION XEvent ON SERVER
ADD EVENT sqlserver.sql_statement_completed
(
    ACTION (
        sqlserver.database_id,
        sqlserver.session_id,
        sqlserver.username,
        sqlserver.client_hostname,
        sqlserver.sql_text,
        sqlserver.tsql_stack
    )
    --WHERE sqlserver.sql_statement_completed.cpu > 100
    --    OR sqlserver.sql_statement_completed.duration > 100
)
ADD TARGET package0.asynchronous_file_target
(
    SET FILENAME = N'D:\XEvent.xet',
    METADATAFILE = 'D:\XEvent.xem'

--To learn the event list, you can execute the following query:
SELECT
    package_name = p.name,
    event_name = o.name
FROM sys.dm_xe_packages p
JOIN sys.dm_xe_objects o ON p.[guid] = o.package_guid
WHERE o.object_type = 'event'

--After creation, we need to run the event:
ALTER EVENT SESSION XEvent ON SERVER STATE = START

--In the general case, you can get data from the trace with the following query:
SELECT
      duration = x.value('(event/data[@name="duration"])[1]', 'INT') / 1000
    , cpu_time = x.value('(event/data[@name="cpu_time"])[1]', 'INT') / 1000
    , logical_reads = x.value('(event/data[@name="logical_reads"])[1]', 'INT')
    , writes = x.value('(event/data[@name="writes"])[1]', 'INT')
    , row_count = x.value('(event/data[@name="row_count"])[1]', 'INT')
    , stmt = x.value('(event/data[@name="statement"])[1]', 'NVARCHAR(MAX)')
    , [db_name] = DB_NAME(x.value('(event/action[@name="database_id"])[1]', 'INT'))
    , end_time = x.value('(event/@timestamp)[1]', 'DATETIME')
FROM (
    SELECT x = CAST(event_data AS XML).query('.')
    FROM sys.fn_xe_file_target_read_file('D:\XEvent*.xet','D:\XEvent*.xem', NULL, NULL)
) t

--When the trace is no longer required, you can turn it off temporarily:
ALTER EVENT SESSION XEvent ON SERVER STATE = STOP

--Or delete it:
IF EXISTS(
    SELECT *
    FROM sys.server_event_sessions
    WHERE name='XEvent'
) DROP EVENT SESSION XEvent ON SERVER

SELECT xevents = COUNT_BIG(*)
FROM sys.dm_xe_objects o
WHERE o.object_type = 'event'
 
SELECT sql_trace = COUNT_BIG(*)
FROM sys.trace_events e

/*
	To view the Extended Events equivalents to SQL Trace events using Query Editor
	https://msdn.microsoft.com/en-us/library/ff878264.aspx?f=255&MSPPError=-2147217396
	https://msdn.microsoft.com/en-us/library/ff878114.aspx
*/
USE MASTER;  
GO  
SELECT DISTINCT  
   tb.trace_event_id,  
   te.name AS 'Event Class',  
   em.package_name AS 'Package',  
   em.xe_event_name AS 'XEvent Name',  
   tb.trace_column_id,  
   tc.name AS 'SQL Trace Column',  
   am.xe_action_name as 'Extended Events action'  
FROM (sys.trace_events te 
LEFT OUTER JOIN sys.trace_xe_event_map em  
   ON te.trace_event_id = em.trace_event_id) 
LEFT OUTER JOIN sys.trace_event_bindings tb  
   ON em.trace_event_id = tb.trace_event_id 
LEFT OUTER JOIN sys.trace_columns tc  
   ON tb.trace_column_id = tc.trace_column_id 
LEFT OUTER JOIN sys.trace_xe_action_map am  
   ON tc.trace_column_id = am.trace_column_id  
ORDER BY te.name, tc.name

SELECT xp.name package_name, xe.name event_name  
   ,xc.name event_field, xc.description  
FROM sys.trace_xe_event_map AS em  
INNER JOIN sys.dm_xe_objects AS xe  
   ON em.xe_event_name = xe.name  
INNER JOIN sys.dm_xe_packages AS xp  
   ON xe.package_guid = xp.guid AND em.package_name = xp.name  
INNER JOIN sys.dm_xe_object_columns AS xc  
   ON xe.name = xc.object_name  
WHERE xe.object_type = 'event' AND xc.column_type <> 'readonly'  
   AND em.xe_event_name = '<event_name>';  


IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='session_name')  
   DROP EVENT SESSION [session_name] ON SERVER;  
CREATE EVENT SESSION [session_name]  
ON SERVER  

ADD EVENT sqlserver.sp_statement_starting  
   (ACTION  
   (  
      sqlserver.nt_username,  
      sqlserver.client_pid,  
      sqlserver.client_app_name,  
      sqlserver.server_principal_name,  
      sqlserver.session_id  
   )  
   WHERE sqlserver.session_id = 59   
   ),  

ADD EVENT sqlserver.sp_statement_completed  
   (ACTION  
   (  
      sqlserver.nt_username,  
      sqlserver.client_pid,  
      sqlserver.client_app_name,  
      sqlserver.server_principal_name,  
      sqlserver.session_id  
   )  
   WHERE sqlserver.session_id = 59 AND duration > 0  
   );  

ADD TARGET package0.asynchronous_file_target  
   (SET filename='c:\temp\ExtendedEventsStoredProcs.xel', metadatafile='c:\temp\ExtendedEventsStoredProcs.xem'); 

SELECT *, CAST(event_data as XML) AS 'event_data_XML'  
FROM sys.fn_xe_file_target_read_file('c:\temp\ExtendedEventsStoredProcs*.xel', 'c:\temp\ExtendedEventsStoredProcs*.xem', NULL, NULL); 

