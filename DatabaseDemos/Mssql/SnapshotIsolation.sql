/*
snapshot isolation level
https://msdn.microsoft.com/en-us/library/bb522682.aspx
transaction isolation level
https://msdn.microsoft.com/en-us/library/ms173763.aspx
snapshot isolation
https://msdn.microsoft.com/en-us/library/tcbchxcb(v=vs.110).aspx
*/
go
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
go
ALTER DATABASE dev ALLOW_SNAPSHOT_ISOLATION ON;

