CREATE DATABASE Development ON
(FILENAME = 'C:\SQL\Data\Development_Primary.mdf')
,(FILENAME = 'C:\SQL\Indexes\Development_Indexes01.mdf')
,(FILENAME = 'C:\SQL\Log\Development_Log.mdf')
FOR ATTACH

CREATE DATABASE awlt2011 ON
(FILENAME = 'C:\SQL\Data\awlt2011_Primary.mdf')
--,(FILENAME = 'C:\SQL\Indexes\awlt2012_Indexes01.mdf')
--,(FILENAME = 'C:\SQL\Log\awlt2012_Log.mdf')
FOR ATTACH

create database AWLT2012
on (filename = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Data\AWLT2012_Primary.mdf')
--,(filename = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Log\AWLT2012_Log.ldf')
for attach
