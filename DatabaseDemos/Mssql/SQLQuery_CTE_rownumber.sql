select top 10 beginbates, endbates, BeginAtt, endatt, TIFFTotalPages from deliverydoc
select 'DatabaseName' = db_name()
go

with bates_CTE (tiffpages, batescount)
as
(select tifftotalpages, cast(right(endbates,9) as int)-cast(right(beginbates,9) as int)+1
from deliverydoc where docid in
	(select docid from userviewdoc where uvid = 14817
	)
)

select tiffpages, batescount,
	'match' = case (tiffpages - batescount)
		when 0 then 'Good'
		else 'Bad' end
from bates_CTE
go

select 'attorder' = row_number() over(partition by beginatt order by beginbates),
	beginbates,endbates,beginatt, endatt
from deliverydoc where docid in
	(select docid from userviewdoc where uvid = 14817
	)
order by beginatt
go


select t.name, c.name from sys.tables t
inner join sys.columns c on t.object_id = c.object_id
where c.name like '%bates%'
order by t.name, c.name
go

EXEC sp_RENAME table_name.old_name, new_name, 'COLUMN'
go



;WITH ShowMessage (STATEMENT,LENGTH)
AS (
	SELECT STATEMENT = CAST('I Like ' AS VARCHAR(300)), LEN('I Like ')
	
	UNION ALL
	
	SELECT CAST(STATEMENT + 'CodeProject! ' AS VARCHAR(300)), LEN(STATEMENT)
	FROM ShowMessage
	WHERE LENGTH < 300
	)
SELECT STATEMENT,LENGTH
FROM ShowMessage

