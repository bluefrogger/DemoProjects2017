/*
https://blogs.msdn.microsoft.com/jason_howell/2014/10/01/what-is-the-rpc-and-rpc-out-option-on-a-sql-server-linked-server/
*/
--Test RPC OUT as false and get the error
EXEC master.dbo.sp_serveroption @server=N'MYSERVER', @optname=N'rpc OUT', @optvalue=N'false'

GO

EXEC [myserver].master.dbo.sp_helpdb
--Msg 7411, Level 16, State 1, Line 1
--Server 'myserver' is not configured for RPC.

GO

--Test RPC OUT as true and see success
EXEC master.dbo.sp_serveroption @server=N'MYSERVER', @optname=N'rpc OUT', @optvalue=N'true'
GO

EXEC [myserver].master.dbo.sp_helpdb
--Command(s) completed successfully.
