use master

restore filelistonly
from disk = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Backup\AdventureWorks2012-Full Database Backup.bak';

restore database AW2012
from disk = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Backup\AdventureWorks2012-Full Database Backup.bak'
with move 'AdventureWorks2012_Data' to 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Data\AW2012_Primary.mdf'
,move 'AdventureWorks2012_Log' to 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Log\AW2012_Log.ldf';

alter database AW2012 set single_user with rollback immediate;
alter database AW2012 modify Name = AW2012;
alter database AW2012 modify file (name = 'AdventureWorks2012_Data', newname = 'AW2012_Primary')
alter database AW2012 modify file (name = 'AdventureWorks2012_Log', newname = 'AW2012_Log')
alter database AW2012 set multi_user;

backup database AW2012 to disk = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Backup\AW2012_Data.bak' with copy_only, format

create database AWLT2012
on (filename = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Data\AWLT2012_Primary.mdf')
--,(filename = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Log\AWLT2012_Log.ldf')
for attach
