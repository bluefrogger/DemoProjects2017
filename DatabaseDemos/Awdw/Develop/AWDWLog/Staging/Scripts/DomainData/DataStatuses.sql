set identity_insert dbo.Statuses on;

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

set identity_insert dbo.Statuses off;
