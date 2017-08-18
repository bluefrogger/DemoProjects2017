-- https://msdn.microsoft.com/en-us/library/bb522469.aspx

/*
A. Adding a file to a database
The following example adds a 5-MB data file to the AdventureWorks2012 database.
*/
USE master;  
GO  
ALTER DATABASE AdventureWorks2012   
ADD FILE   
(  
    NAME = Test1dat2,  
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\t1dat2.ndf',  
    SIZE = 5MB,  
    MAXSIZE = 100MB,  
    FILEGROWTH = 5MB  
);  
GO  
  
/*B. Adding a filegroup with two files to a database
The following example creates the filegroup Test1FG1 in the AdventureWorks2012 database and adds two 5-MB files to the filegroup.
*/
USE master  
GO  
ALTER DATABASE AdventureWorks2012  
ADD FILEGROUP Test1FG1;  
GO  
ALTER DATABASE AdventureWorks2012   
ADD FILE   
(  
    NAME = test1dat3,  
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\t1dat3.ndf',  
    SIZE = 5MB,  
    MAXSIZE = 100MB,  
    FILEGROWTH = 5MB  
),  
(  
    NAME = test1dat4,  
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\t1dat4.ndf',  
    SIZE = 5MB,  
    MAXSIZE = 100MB,  
    FILEGROWTH = 5MB  
)  
TO FILEGROUP Test1FG1;  
GO  

/*
C. Adding two log files to a database
The following example adds two 5-MB log files to the AdventureWorks2012 database.
*/
USE master;  
GO  
ALTER DATABASE AdventureWorks2012   
ADD LOG FILE   
(  
    NAME = test1log2,  
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\test2log.ldf',  
    SIZE = 5MB,  
    MAXSIZE = 100MB,  
    FILEGROWTH = 5MB  
),  
(  
    NAME = test1log3,  
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\test3log.ldf',  
    SIZE = 5MB,  
    MAXSIZE = 100MB,  
    FILEGROWTH = 5MB  
);  
GO  
 
/*
D. Removing a file from a database
The following example removes one of the files added in example B.
*/

USE master;  
GO  
ALTER DATABASE AdventureWorks2012  
REMOVE FILE test1dat4;  
GO  
  
/*
E. Modifying a file
The following example increases the size of one of the files added in example B.
The ALTER DATABASE with MODIFY FILE command can only make a file size bigger, so if you need to make the file size smaller you need to use DBCC SHRINKFILE.
*/

USE master;  
GO
  
ALTER DATABASE AdventureWorks2012   
MODIFY FILE  
(NAME = test1dat3,  
SIZE = 200MB);  
GO  

/*
This example shrinks the size of a data file to 100 MB, and then specifies the size at that amount.
*/

USE AdventureWorks2012;
GO

DBCC SHRINKFILE (AdventureWorks2012_data, 100);
GO

USE master;  
GO
  
ALTER DATABASE AdventureWorks2012   
MODIFY FILE  
(NAME = test1dat3,  
SIZE = 200MB);  
GO

/*
F. Moving a file to a new location
The following example moves the Test1dat2 file created in example A to a new directory.
System_CAPS_ICON_note.jpg Note
You must physically move the file to the new directory before running this example. Afterward, stop and start the instance of SQL Server or take the AdventureWorks2012 database OFFLINE and then ONLINE to implement the change.
*/


USE master;  
GO  
ALTER DATABASE AdventureWorks2012  
MODIFY FILE  
(  
    NAME = Test1dat2,  
    FILENAME = N'c:\t1dat2.ndf'  
);
/*
G. Moving tempdb to a new location
The following example moves tempdb from its current location on the disk to another disk location. Because tempdb is re-created each time the MSSQLSERVER service is started, you do not have to physically move the data and log files. The files are created when the service is restarted in step 3. Until the service is restarted, tempdb continues to function in its existing location.

*/

--Determine the logical file names of the tempdb database and their current location on disk.

SELECT name, physical_name  
FROM sys.master_files  
WHERE database_id = DB_ID('tempdb');  
GO  

--Change the location of each file by using ALTER DATABASE.

USE master;  
GO  
ALTER DATABASE tempdb   
MODIFY FILE (NAME = tempdev, FILENAME = 'E:\SQLData\tempdb.mdf');  
GO  
ALTER DATABASE  tempdb   
MODIFY FILE (NAME = templog, FILENAME = 'E:\SQLData\templog.ldf');  
GO  

--Stop and restart the instance of SQL Server.
--Verify the file change.

SELECT name, physical_name  
FROM sys.master_files  
WHERE database_id = DB_ID('tempdb');  

--Delete the tempdb.mdf and templog.ldf files from their original location.
/*
H. Making a filegroup the default
The following example makes the Test1FG1 filegroup created in example B the default filegroup. Then, the default filegroup is reset to the PRIMARY filegroup. Note that PRIMARY must be delimited by brackets or quotation marks.
*/

USE master;  
GO  
ALTER DATABASE AdventureWorks2012   
MODIFY FILEGROUP Test1FG1 DEFAULT;  
GO  
ALTER DATABASE AdventureWorks2012   
MODIFY FILEGROUP [PRIMARY] DEFAULT;  
GO  
  
/*
I. Adding a Filegroup Using ALTER DATABASE
The following example adds a FILEGROUP that contains the FILESTREAM clause to the FileStreamPhotoDB database.
*/
--Create and add a FILEGROUP that CONTAINS the FILESTREAM clause to  
--the FileStreamPhotoDB database.  
ALTER DATABASE FileStreamPhotoDB  
ADD FILEGROUP TodaysPhotoShoot  
CONTAINS FILESTREAM;  
GO  
  
--Add a file for storing database photos to FILEGROUP   
ALTER DATABASE FileStreamPhotoDB  
ADD FILE  
(  
    NAME= 'PhotoShoot1',  
    FILENAME = 'C:\Users\Administrator\Pictures\TodaysPhotoShoot.ndf'  
)  
TO FILEGROUP TodaysPhotoShoot;  
GO  


--https://msdn.microsoft.com/en-us/library/ms345483.aspx
ALTER DATABASE database_name SET OFFLINE;  
ALTER DATABASE database_name MODIFY FILE ( NAME = logical_name, FILENAME = 'new_path\os_file_name' );  
ALTER DATABASE database_name SET ONLINE;  

SELECT * FROM sys.master_files AS mf

ALTER DATABASE awlt2011 SET OFFLINE;  
ALTER DATABASE awlt2011 MODIFY FILE ( NAME = AdventureWorksLT2008_Log, FILENAME = 'C:\SQL\Log\awlt2011_log.ldf' );  
ALTER DATABASE awlt2011 SET ONLINE;  

alter database AW2012 set single_user with rollback immediate;
alter database AW2012 modify Name = AW2012;
alter database AW2012 modify file (name = 'AdventureWorks2012_Data', newname = 'AW2012_Primary')
alter database AW2012 modify file (name = 'AdventureWorks2012_Log', newname = 'AW2012_Log')
alter database AW2012 set multi_user;

alter database ElevateDev SET trustworthy on