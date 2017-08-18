USE dev

declare @hexstring varchar(max) = '0xabcedf012439';

select CONVERT(varbinary(max), @hexstring, 0);
select CONVERT(varbinary(max), @hexstring, 1);
--select CONVERT(varbinary(max), @hexstring, 2);

set @hexstring = 'abcedf012439';
select CONVERT(varbinary(max), @hexstring, 0);
--select CONVERT(varbinary(max), @hexstring, 1);
select CONVERT(varbinary(max), @hexstring, 2);

go

declare @hexbin varbinary(max) = 0xabcedf012439;

SELECT CONVERT(varchar(max), @hexbin, 1)
SELECT CONVERT(varchar(max), @hexbin, 2);

go