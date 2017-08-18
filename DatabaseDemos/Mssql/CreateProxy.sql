/*https://www.mssqltips.com/sqlservertip/2163/running-a-ssis-package-from-sql-server-agent-using-a-proxy-account/
	https://www.simple-talk.com/sql/database-administration/setting-up-your-sql-server-agent-correctly/
*/
 --Script #1 - Creating a credential to be used by proxy
USE MASTER
GO

--Drop the credential if it is already existing
IF EXISTS (SELECT 1 FROM sys.credentials WHERE name = N'SsisCredentials')
BEGIN
DROP CREDENTIAL SsisCredentials
END
GO

CREATE LOGIN [AlexY10\SsisProxy] FROM WINDOWS
CREATE USER SsisProxy FROM LOGIN [AlexY10\SsisProxy]

CREATE CREDENTIAL [SSISCredentials]
WITH IDENTITY = N'AlexY10\SsisProxy',
SECRET = N'Sunshine9'
GO

--Script #2 - Creating a proxy account
USE msdb
GO
--Create a proxy and use the same credential as created above
EXEC msdb.dbo.sp_add_proxy
	@proxy_name = N'AlexY10\SsisProxy',
	@credential_name = N'SsisCredentials',
	@enabled=1
GO
--To enable or disable you can use this command
EXEC msdb.dbo.sp_update_proxy
	@proxy_name = N'SsisProxy',
	@enabled = 1 --@enabled = 0
GO

--Drop the proxy if it is already existing
IF EXISTS (SELECT 1 FROM msdb.dbo.sysproxies WHERE name = N'SsisProxy')
BEGIN
EXEC dbo.sp_delete_proxy
	@proxy_name = N'SsisProxy'
END
GO

EXEC sp_grant_login_to_proxy @login_name = 'BCNT.LOCAL\alex.yoo', @proxy_name = 'AlexY10\SsisProxy'
EXEC sp_revoke_login_from_proxy @name = '', @proxy_name = ''
