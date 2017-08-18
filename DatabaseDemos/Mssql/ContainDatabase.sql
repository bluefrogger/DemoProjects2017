/*
https://msdn.microsoft.com/en-us/library/ff929139.aspx
*/

SELECT containment,* FROM sys.databases WHERE name = 'ElevateDev'
EXEC sys.sp_columns @table_name = 'databases'
EXEC sys.sp_help 'sp_columns'
SELECT * FROM sys.servers
sp_configure 'contained database authentication', 1;  
GO  
RECONFIGURE;
GO  
EXEC sys.sp_configure

USE [master]  
GO  
ALTER DATABASE ElevateDev SET CONTAINMENT = PARTIAL  
GO

DECLARE @username sysname ;  
DECLARE user_cursor CURSOR  
    FOR   
        SELECT dp.name   
        FROM sys.database_principals AS dp  
        JOIN sys.server_principals AS sp   
        ON dp.sid = sp.sid  
        WHERE dp.authentication_type = 1 AND sp.is_disabled = 0;  
OPEN user_cursor  
FETCH NEXT FROM user_cursor INTO @username  
    WHILE @@FETCH_STATUS = 0  
    BEGIN  
        EXECUTE sp_migrate_user_to_contained   
        @username = @username,  
        @rename = N'keep_name',  
        @disablelogin = N'disable_login';  
    FETCH NEXT FROM user_cursor INTO @username  
    END  
CLOSE user_cursor ;  
DEALLOCATE user_cursor ;  
