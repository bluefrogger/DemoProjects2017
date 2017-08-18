;with Tally(nb) as
(
	select 0
	union all
	select row_number() over (order by (select null))
	from (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as aa(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as bb(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as cc(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as dd(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as ee(nb)
)
merge dbo.Tally as tar
using (
select nb from Tally
	) as src(nb)
on tar.nb = src.nb
when not matched by target then
	insert (nb)
	values (src.nb);

go
merge dbo.TallyChar as tar
using(
	select nb, char(nb) as ch from dbo.tally where nb <= 127
	) as src(nb, ch)
on tar.nb = src.nb
when not matched by target then
	insert (nb, ch)
	values (src.nb, src.ch);
