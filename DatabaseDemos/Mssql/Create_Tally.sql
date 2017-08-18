	
	with e1(n) as
	(
	   select 1 union all select 1 union all select 1 union all select 1 union all
	   select 1 union all select 1 union all select 1 union all select 1 union all
	   select 1 union all select 1 union all select 1 union all select 1 union all
	   select 1 union all select 1 union all select 1 union all select 1
	)
	,e2(n) as (select 1 from e1 cross join e1 as aa)
	,e3(n) as (select 1 from e2 cross join e2 as aa)
	select row_number() over(order by n) as n from e3 order by n