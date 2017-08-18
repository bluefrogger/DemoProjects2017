/*
Do not change the database path or name variables.
Any sqlcmd variables will be properly substituted during 
build and deployment.
*/
ALTER DATABASE [$(DatabaseName)]
	ADD FILE
	(
		NAME = [DataFiles_01],
		FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_DataFiles_01.ndf'
	)
TO FILEGROUP DataFiles;
