CREATE SERVICE [ExtractTargetService]
	ON QUEUE dbo.ExtractTargetQueue
	(
		ExtractContract
	)
