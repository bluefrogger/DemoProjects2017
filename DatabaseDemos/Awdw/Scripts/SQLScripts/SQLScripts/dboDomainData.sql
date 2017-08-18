
MERGE dbo.Statuses AS tar
USING(VALUES
	 (1, 'Error', ''),
	 (2, 'NA', ''),
	 (3, 'Stopped', ''),
	 (4, 'Waiting', ''),
	 (5, 'Running', ''),
	 (6, 'Completed', '')) AS src(Id, Name, Detail)
ON tar.Id = src.Id
	WHEN NOT MATCHED BY TARGET THEN 
	INSERT (Id, Name, Detail) 
	VALUES (src.Id, src.Name, src.Detail);

select * from dbo.Statuses
--select * from dbo.LogActivity
--select * from dbo.LogError

;with Tally(nb) as
(
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

set identity_insert dbo.Settings on;

merge dbo.Settings as tar
using (
	values 
	(1, 'Debug', '', 0, 0, 7)
	, (2, 'Verbose', '', 0, 0, 7)
) as src(Id, Name, Detail, Value, ValueDefault, SettingStatus)
on tar.Id = src.Id
when not matched by target then
insert (Id, Name, Detail, Value, ValueDefault, SettingStatus)
values (src.Id, src.Name, src.Detail, src.Value, src.ValueDefault, src.SettingStatus);

set identity_insert dbo.Settings off;

use staging
select * from dbo.Settings
