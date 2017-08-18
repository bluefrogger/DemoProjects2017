CREATE LOGIN [alex.yoo] WITH PASSWORD = 'Sunshine9'

USE msdb

CREATE USER [alex.yoo] FOR LOGIN [alex.yoo];

EXEC sp_addrolemember 'SQLAgentOperatorRole', 'SQLReporter01'

CREATE PROC dbo.myTest
WITH EXECUTE AS 'SQLReporter01'
AS
begin
	
	EXEC sql2.msdb.dbo.sp_start_job @job_id = N'EA9ED5CA-8CB5-4851-9E32-84B2226B837A'
END


DROP PROC dbo.myTest