/*
 Pre-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.	
 Use SQLCMD syntax to include a file in the pre-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the pre-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
exec sp_configure 'show_advanced_options', 1;

reconfigure;

exec sp_configure 'clr enabled', 1;

exec sp_configure 'show_advanced_options', 0;

go
/*
use $(DatabaseName);

GO
CREATE ASSEMBLY [AWDWClr]
    FROM '$(DLLPath)'
    --WITH PERMISSION_SET = UNSAFE;


GO
PRINT N'Creating [dbo].[TimeZoneInfoLocal2UTC]...';


GO
CREATE FUNCTION [dbo].[TimeZoneInfoLocal2UTC]
(@local DATETIME)
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [AWDWClr].[UserDefinedFunctions].[TimeZoneInfoLocal2UTC]


GO
PRINT N'Creating [dbo].[TimeZoneInfoUTC2Local]...';


GO
CREATE FUNCTION [dbo].[TimeZoneInfoUTC2Local]
(@utc DATETIME)
RETURNS NVARCHAR (MAX)
AS
 EXTERNAL NAME [AWDWClr].[UserDefinedFunctions].[TimeZoneInfoUTC2Local]

go
use master;

go
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
BEGIN
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = '123456'
END

go
if exists (select * from sys.database_principals where name = 'AWDWClrUser')
begin
	drop user AWDWClrUser
end
if exists (select * from sys.server_principals where name = 'AWDWClrLogin')
begin
	drop login [AWDWClrLogin]
end
if exists (select * from sys.asymmetric_keys where name = 'AWDWClrKey')
begin
	DROP ASYMMETRIC KEY [AWDWClrKey];
end

CREATE ASYMMETRIC KEY AWDWClrKey
	from executable file = '$(DLLPath)'
		--FROM FILE = 'D:\VisualStudio\SharedDLL\AWDWClrKey.snk'

go
CREATE LOGIN [AWDWClrLogin] FROM ASYMMETRIC KEY AWDWClrKey;

go
GRANT UNSAFE ASSEMBLY TO AWDWClrLogin;

go
use $(DatabaseName);
alter assembly AWDWClr with permission_set = unsafe;
*/