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
