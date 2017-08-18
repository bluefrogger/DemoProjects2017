/*
https://technet.microsoft.com/en-us/library/ms181153(v=sql.105).aspx
https://msdn.microsoft.com/en-us/library/ms190268.aspx
http://borishristov.com/blog/modifying-not-owned-sql-agent-jobs-without-being-a-sysadmin/
*/
Execute sp_add_job --to create a job.
Execute sp_add_jobstep --to create one or more job steps.
Execute sp_add_schedule --to create a schedule.
Execute sp_attach_schedule --to attach a schedule to the job.
Execute sp_add_jobserver --to set the server for the job.
/*
	Local jobs are cached by the local SQL Server Agent. 
	Therefore, any modifications implicitly force SQL Server Agent to re-cache the job. 
	Because SQL Server Agent does not cache the job until sp_add_jobserver is CALLED
	, it is more efficient to call sp_add_jobserver last.
*/

select sys.schemas.name 'Schema'
, sys.objects.name Object
, sys.database_principals.name username
, sys.database_permissions.type permissions_type
, sys.database_permissions.permission_name
, sys.database_permissions.state permission_state
, sys.database_permissions.state_desc
, state_desc + ' ' + permission_name + ' on ['+ sys.schemas.name + '].[' + sys.objects.name + '] to [' + sys.database_principals.name + ']' COLLATE LATIN1_General_CI_AS
from sys.database_permissions
left outer join sys.objects on sys.database_permissions.major_id = sys.objects.object_id
left outer join sys.schemas on sys.objects.schema_id = sys.schemas.schema_id
left outer join sys.database_principals on sys.database_permissions.grantee_principal_id = sys.database_principals.principal_id
WHERE sys.database_principals.name = 'BCNT.LOCAL\alex.yoo'
order by 1, 2, 3, 5

USE msdb;
GO

EXEC dbo.sp_add_job @job_name = N'BC_jb_SSRS_ProcessCheckRegQueue2' ;
EXEC dbo.sp_delete_job @job_name = N'BC_jb_SSRS_ProcessCheckRegQueue2' ;

EXECUTE AS LOGIN = 'NT Authority\Network Service'
EXEC sp_add_jobstep
    @job_name = N'BC_jb_SSRS_ProcessCheckRegQueue',  
    @step_name = N'Call Ssis',
    @subsystem = N'Dts',  
    --@command = N'ALTER DATABASE SALES SET READ_ONLY',   
    @retry_attempts = 2,  
    @retry_interval = 1;
EXEC sp_delete_jobstep 
	@job_name = N'BC_jb_SSRS_ProcessCheckRegQueue',  
	@step_id = 1
EXEC dbo.sp_add_schedule  
    @schedule_name = N'RunOnce',  
    @freq_type = 1,  
    @active_start_time = 233000;

EXEC sp_add_schedule  
    @schedule_name = N'NightlyJobs' ,  
    @freq_type = 4,  
    @freq_interval = 1,  
    @active_start_time = 010000 ;  
GO  
  
EXEC sp_attach_schedule  
   @job_name = N'BackupDatabase',  
   @schedule_name = N'NightlyJobs' ;  
GO  
  
EXEC sp_attach_schedule  
   @job_name = N'RunReports',  
   @schedule_name = N'NightlyJobs' ;  
GO
EXEC dbo.sp_add_jobserver  
    @job_name = N'Weekly Sales Backups',  
    @server_name = N'SEATTLE2' ;  
GO  


SELECT * FROM dbo.sysjobs WHERE name = 'BC_jb_SSRS_ProcessCheckRegQueue2'
SELECT * FROM dbo.sysjobsteps WHERE job_id = 'FACB303A-F7D9-4485-B2AC-5BD1506D8D7A'

EXEC dbo.sp_start_job @job_name = 'BC_jb_SSRS_ProcessCheckRegQueue2';


USE msdb ;  
GO  
EXEC dbo.sp_add_job  
    @job_name = N'Weekly Sales Data Backup' ;  
GO  
EXEC sp_add_jobstep  
    @job_name = N'Weekly Sales Data Backup',  
    @step_name = N'Set database to read only',  
    @subsystem = N'TSQL',  
    @command = N'ALTER DATABASE SALES SET READ_ONLY',   
    @retry_attempts = 5,  
    @retry_interval = 5 ;  
GO  
EXEC dbo.sp_add_schedule  
    @schedule_name = N'RunOnce',  
    @freq_type = 1,  
    @active_start_time = 233000 ;  
USE msdb ;  
GO  
EXEC sp_attach_schedule  
   @job_name = N'Weekly Sales Data Backup',  
   @schedule_name = N'RunOnce';  
GO  
EXEC dbo.sp_add_jobserver  
    @job_name = N'Weekly Sales Data Backup';  
GO  
