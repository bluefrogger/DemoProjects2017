/*
Do not change the database path or name variables.
Any sqlcmd variables will be properly substituted during 
build and deployment.
*/
ALTER DATABASE [$(DatabaseName)]
ADD FILE(
	NAME = 'Staging_Primary'
	, FILENAME = '$(DefaultDataPath)\$(DatabaseName)_Primary.mdf'
	, SIZE = 1 MB
    , MAXSIZE = UNLIMITED
	, FILEGROWTH = 10%
)
