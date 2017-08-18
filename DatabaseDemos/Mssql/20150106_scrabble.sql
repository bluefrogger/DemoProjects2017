/*
if exists (
	select 1
	from sys.objects
	where name = 'MaybeBuildNumberTable')
		begin
			drop procedure MaybeBuildNumberTable
		end
go

create proc dbo.MaybeBuildNumberTable
as
begin
	
	if not exists (
		select 1 from dbo.sysobjects
		where id = object_id(N'dbo.Numbers')
		and objectproperty(id, N'isUserTable') = 1
	)
	begin
		create table dbo.Numbers (
			number int
			,constraint index_numbers primary key clustered (number asc)
		)
	end

	if not exists (
		select 1
		from numbers
		where number = 99999
	)
	begin
		truncate table numbers
		;with digits(ii) as (
			select ii
			from (
				values (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) as xx(ii)
		)
		insert into numbers(number)
		select (d5.ii * 100000 + d4.ii * 10000 + d3.ii * 1000 + d2.ii * 100 + d1.ii * 10 + d0.ii + 1) as seq
		from digits as d0
		cross join digits as d1
		cross join digits as d2
		cross join digits as d3
		cross join digits as d4
		cross join digits as d5
		order by seq
	end
end
*/

if exists (
	select 1
	from sys.objects
	where name = 'PermutationsOf'
)
drop function PermutationOf
go

--create function PermutationOf(@String varchar(10))
;
declare @str varchar(6) = 'test'
select len(@str),substring(@str, 4, len(@str) - 4)

