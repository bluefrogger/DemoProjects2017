USE master
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'SQL2', @useself = N'false'
	, @locallogin = N'alex.yoo', @rmtuser = N'alex.yoo', @rmtpassword = N'Sunshine9'

GO

