	EXEC tempdb.dbo.sp_help '#tmpProdOptRelSuperSet'

	SELECT co.name, co.max_length, ty.name FROM tempdb.sys.columns AS co
	JOIN tempdb.sys.types AS ty ON co.system_type_id = ty.system_type_id
	WHERE object_id = OBJECT_ID('tempdb..#tmpProdOptRelSuperSet')
		