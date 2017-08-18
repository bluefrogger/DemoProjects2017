alter database test set single_user with rollback immediate
drop database test

create database test
use test

go
create assembly helloworld from 'D:\VisualStudio\AWDW\Scripts\AWDWScripts\AWDWClr\obj\Debug\AWDWClr.dll'
with permission_set = safe

go
create proc dbo.hello(
	@output nvarchar(50) output
)as
external name helloworld.UserDefinedFunctions.HelloWorld

go
declare @output nvarchar(50)
exec dbo.hello @output = @output output
