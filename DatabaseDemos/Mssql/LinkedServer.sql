
EXEC sys.sp_addlinkedserver  @server = N'shsql1', @srvproduct = N'SQL SERVER'
EXEC sys.sp_addlinkedsrvlogin @rmtsrvname = 'shsql1', @useself = 'false', @locallogin = 'BCNT.LOCAL\alex.yoo', @rmtuser = 'alex.yoo', @rmtpassword = 'Sunshine9'
