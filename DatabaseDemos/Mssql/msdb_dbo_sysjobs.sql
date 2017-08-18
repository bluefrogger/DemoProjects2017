CREATE FUNCTION dbo.SqlAgentJob_GetStatus (@JobName sysname)
    RETURNS TABLE
AS
RETURN
SELECT TOP 1
    JobName        = j.name,
    IsRunning      = CASE
                       WHEN ja.job_id IS NOT NULL
                           AND ja.stop_execution_date IS NULL
                         THEN 1 ELSE 0 
                       END,
    RequestSource  = ja.run_requested_source,
    LastRunTime    = ja.start_execution_date,
    NextRunTime    = ja.next_scheduled_run_date,
    LastJobStep    = js.step_name,
    RetryAttempt   = jh.retries_attempted,
    JobLastOutcome = CASE
                       WHEN ja.job_id IS NOT NULL
                           AND ja.stop_execution_date IS NULL THEN 'Running'
                       WHEN jh.run_status = 0 THEN 'Failed'
                       WHEN jh.run_status = 1 THEN 'Succeeded'
                       WHEN jh.run_status = 2 THEN 'Retry'
                       WHEN jh.run_status = 3 THEN 'Cancelled'
                     END
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobactivity ja 
    ON ja.job_id = j.job_id
       AND ja.run_requested_date IS NOT NULL
       AND ja.start_execution_date IS NOT NULL
LEFT JOIN msdb.dbo.sysjobsteps js
    ON js.job_id = ja.job_id
       AND js.step_id = ja.last_executed_step_id
LEFT JOIN msdb.dbo.sysjobhistory jh
    ON jh.job_id = j.job_id
       AND jh.instance_id = ja.job_history_id
WHERE j.name = @JobName
ORDER BY ja.start_execution_date DESC;
GO
Because it’s a TVF, you can pass a value directly to it and get a result set back:

1
2
SELECT *
FROM dbo.SqlAgentJob_GetStatus('Test Job')
Or APPLY it across a table for a set of results (in this case I’m getting all job in job_category 10):

1
2
3
4
SELECT sts.*
FROM msdb.dbo.sysjobs j
CROSS APPLY dbo.SqlAgentJob_GetStatus(j.name) sts
WHERE j.category_id = 10;
Or get a list of all SQL Agent jobs that are currently running:

1
2
3
4
SELECT sts.*
FROM msdb.dbo.sysjobs j
CROSS APPLY dbo.SqlAgentJob_GetStatus(j.name) sts
WHERE sts.IsRunning = 1