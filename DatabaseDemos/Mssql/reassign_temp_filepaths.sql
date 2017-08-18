use tempdb;
go

--execute sp_helpfile;
go

alter database tempdb
modify file (name=tempdev, filename='c:\tempdb.mdf');
go

alter database tempdb
modify file (name = templog, filename = 'c:\templog.ldf');
go


