USE master

CREATE DATABASE ODS
ON PRIMARY
(
	NAME = ODS_Primary
	,FILENAME = 'C:\SQL\Data\ODS_Primary.mdf'
	,SIZE = 4 MB
    ,MAXSIZE = UNLIMITED
	,FILEGROWTH = 10 MB
)
,FILEGROUP fgIndexes
(
	NAME = ODS_Indexes01
	,FILENAME = 'C:\SQL\Indexes\ODS_Indexes01.ndf'
	,SIZE = 4 MB
    ,MAXSIZE = UNLIMITED
    ,FILEGROWTH = 10 mb
)
LOG ON
(
	NAME = ODS_Log
	,FILENAME = 'C:\SQL\Log\ODS_Log.ldf'
	,SIZE = 1 MB
    ,MAXSIZE = UNLIMITED
    ,FILEGROWTH = 10 %
)

ALTER DATABASE ElevateDev SET TRUSTWORTHY ON;


CREATE DATABASE Development
ON PRIMARY
(
	NAME = Development_Primary
	,FILENAME = 'C:\SQL\Data\Development_Primary.mdf'
	,SIZE = 4 MB
    ,MAXSIZE = UNLIMITED
	,FILEGROWTH = 10 MB
)
,FILEGROUP fgIndexes
(
	NAME = Development_Indexes01
	,FILENAME = 'C:\SQL\Indexes\Development_Indexes01.ndf'
	,SIZE = 4 MB
    ,MAXSIZE = UNLIMITED
    ,FILEGROWTH = 10 mb
)
LOG ON
(
	NAME = Development_Log
	,FILENAME = 'C:\SQL\Log\Development_Log.ldf'
	,SIZE = 1 MB
    ,MAXSIZE = UNLIMITED
    ,FILEGROWTH = 10 %
)


create database AWDW
on primary
(
	name = 'AWDW'
	,filename = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Data\AWDW_Primary.mdf'
)
,filegroup DataFiles
(
	name = 'AWDW_DataFile_01'
	,filename = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Data\AWDW_DataFile_01'
)
log on
(
	name = 'AWDW_log'
	,filename = 'D:\MSSQLServer\MSSQL12.MSSQLSERVER\MSSQL\Log\AWDW_log.ldf'
)

select * from sys.filegroups
select * from sys.database_files


SELECT suser_sname(owner_sid) FROM sys.databases WHERE name = 'ElevateDev'
EXEC sys.sp_columns @table_name = 'databases'

