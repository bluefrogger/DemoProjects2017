CREATE SERVICE [ExtractInitService]
	ON QUEUE dbo.ExtractInitQueue
	(
		ExtractContract
	)
