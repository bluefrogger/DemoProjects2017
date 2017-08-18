/*
http://marlonribunal.com/who-are-the-sysadmins-in-this-sql-server/
*/

USE master
GO
 
SELECT  p.name AS [loginname] ,
        p.type ,
        p.type_desc ,
        p.is_disabled,
        CONVERT(VARCHAR(10),p.create_date ,101) AS [created],
        CONVERT(VARCHAR(10),p.modify_date , 101) AS [update]
		,s.sysadmin
FROM    sys.server_principals p
        JOIN sys.syslogins s ON p.sid = s.sid
WHERE   p.type_desc IN ('SQL_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
        -- Logins that are not process logins
        AND p.name NOT LIKE '##%'
        -- Logins that are sysadmins
        AND s.sysadmin = 1
GO

EXEC sp_helpsrvrolemember 'sysadmin'
EXEC sp_helpsrvrole