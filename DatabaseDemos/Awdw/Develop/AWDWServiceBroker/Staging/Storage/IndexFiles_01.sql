/*
Do not change the database path or name variables.
Any sqlcmd variables will be properly substituted during 
build and deployment.
*/
ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [IndexFiles_01],
		FILENAME = 'C:\SQL\Indexes\$(DefaultFilePrefix)_IndexFiles_01.ndf'
	)
TO FILEGROUP IndexFiles	
