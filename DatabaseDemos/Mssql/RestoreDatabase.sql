
RESTORE FILELISTONLY FROM DISK = '\\NFS3\DatabaseBackup\ShSqlDev\PMCPBranchDev_backup_2016_07_18_013002_5387379.bak';

RESTORE DATABASE PMCPBranchDev
FROM DISK = '\\NFS3\DatabaseBackup\ShSqlDev\PMCPBranchDev_backup_2016_09_16_013002_3156504.bak'
WITH MOVE 'PMCPBranchDev' TO 'C:\SQL\Data\PMCPBranchDev_Primary.mdf'
,MOVE 'PMCPBranchDev_log' TO 'C:\SQL\Log\PMCPBranchDev_Log.ldf';

USE master;

RESTORE FILELISTONLY
FROM DISK = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Backup\AdventureWorks2012-Full Database Backup.bak';

RESTORE DATABASE AW2012
FROM DISK = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Backup\AdventureWorks2012-Full Database Backup.bak'
WITH MOVE 'AdventureWorks2012_Data' TO 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Data\AW2012_Primary.mdf'
,MOVE 'AdventureWorks2012_Log' TO 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Log\AW2012_Log.ldf';

USE master;  
GO  
ALTER DATABASE PMCPBranchDev180716  
Modify Name = PMCPBranchDev;  
GO  
