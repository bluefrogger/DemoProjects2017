--/*
-- Pre-Deployment Script Template							
----------------------------------------------------------------------------------------
-- This file contains SQL statements that will be executed before the build script.	
-- Use SQLCMD syntax to include a file in the pre-deployment script.			
-- Example:      :r .\myfile.sql								
-- Use SQLCMD syntax to reference a variable in the pre-deployment script.		
-- Example:      :setvar TableName MyTable							
--               SELECT * FROM [$(TableName)]					
----------------------------------------------------------------------------------------
--*/
--USE master;

--GO
--IF NOT EXISTS
--(
--	SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101
--)
--BEGIN
--	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Sunshine1!';
--END;

--GO
--IF EXISTS
--(
--	SELECT * FROM sys.database_principals WHERE name = 'AWDWClrUser'
--)
--BEGIN
--	DROP user AWDWClrUser;
--END;
--IF EXISTS
--(
--	SELECT * FROM sys.server_principals WHERE name = 'AWDWClrLogin'
--)
--BEGIN
--	DROP LOGIN AWDWClrLogin;
--END;
--IF EXISTS
--(
--	SELECT * FROM sys.asymmetric_keys WHERE name = 'AWDWClrKey'
--)
--BEGIN
--	DROP ASYMMETRIC KEY [AWDWClrKey];
--END;

--go
--open master key decryption by password = 'Sunshine1!'

--go
--CREATE ASYMMETRIC KEY AWDWClrKey 
--	--FROM EXECUTABLE FILE = '$(DLLPath)';
--	FROM FILE = 'C:\Users\Alex.yoo\Documents\Visual Studio 2015\Projects\AWDW\Docs\AWDWClrKey.snk'

--GO
--close master key

--GO
--CREATE LOGIN AWDWClrLogin FROM ASYMMETRIC KEY AWDWClrKey;

--GO
--GRANT UNSAFE ASSEMBLY TO AWDWClrLogin;

--use $(DatabaseName);
EXEC sp_serveroption 'AlexY10', 'data access', 'true';