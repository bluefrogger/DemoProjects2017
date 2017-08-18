USE [AlexTest]
GO
/****** Object:  StoredProcedure [dbo].[LawSize]    Script Date: 5/3/2014 3:24:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----Law Extracted size
ALTER PROCEDURE [dbo].[LawSize] (
	@db NVARCHAR(max)
	,@filter NVARCHAR(max)
	,@value NVARCHAR(max)
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(max)

	SET @sql = 'SELECT ''parentsizegb'' = cast(cast(sum(filesize) AS NUMERIC) / 1024 / 1024 / 1024 AS NUMERIC(18, 3))
	FROM srm22.' + @db + '.dbo.tbldoc with(nolock) WHERE ' 
	+ @filter + ' = ''' + @value + ''' AND (attachpid = 0 OR attachpid = id)'
	+ ' select ''parent count'' = count(*) from srm22.' + @db + '.dbo.tbldoc with(nolock) WHERE ' 
	+ @filter + ' = ''' + @value + ''' AND (attachpid = 0 OR attachpid = id)'
	+ 'SELECT ''famsizegb''= cast(cast(sum(filesize) AS NUMERIC) / 1024 / 1024 / 1024 AS NUMERIC(18, 3))
	FROM srm22.' + @db + '.dbo.tbldoc with(nolock) WHERE ' 
	+ @filter + ' = ''' + @value + '''' 
	+ ' select ''doc count'' = count(*) from srm22.' + @db + '.dbo.tbldoc with(nolock) WHERE ' 
	+ @filter + ' = ''' + @value + '''' 
	+ ' select ''page count'' = count(*) from srm22.' + @db + '.dbo.tbldoc as d with(nolock) left outer join ' 
	+ @db + '.dbo.tblpage as p with(nolock) on d.id = p.id WHERE ' 
	+ @filter + ' = ''' + @value + '''' 
	+ ' select ''first beg doc'' = min(begdoc#), ''last end doc'' = max(enddoc#) from srm22.' 
	+ @db + '.dbo.tbldoc with(nolock) WHERE ' 
	+ @filter + ' = ''' + @value + '''' 
	+ ' select distinct name as ''custodian'' from srm22.' + @db + '.dbo.tbldoc as d with(nolock) inner join ' 
	+ @db + '.dbo.tblcustodians as c with(nolock) on d.custodianid = c.id WHERE ' 
	+ @filter + ' = ''' + @value + ''''
	+ ' select distinct srm_exportvolume as ''volume'' from srm22.' 
	+ @db + '.dbo.tbldoc with(nolock) WHERE ' 
	+ @filter + ' = ''' + @value + '''' 

	Execute (@sql)
END


USE [ReportServer_SP]
GO
/****** Object:  StoredProcedure [dbo].[VPSize]    Script Date: 5/11/2014 7:52:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----VP Extracted size
ALTER PROCEDURE [dbo].[VPSize] (
	@db NVARCHAR(max)
	,@view NVARCHAR(max)
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(max);

	SET @sql = 
		' SELECT ''parentsize_r(gb)'' = CAST(SUM(CAST(edfs_orifilesize AS NUMERIC)) / 1024 / 1024 / 1024 AS NUMERIC(18, 3)) FROM srm23.'
		+ @db + '_review.dbo.reviewedoc as r with(nolock) INNER JOIN srm23.'
		+ @db + '_review.dbo.userviewdoc as v ON r.docid = v.docid WHERE r.docid = ed_basedocid AND UVID = ' + @view
		+ ' SELECT ''famsize_r(gb)'' = CAST(SUM(CAST(edfs_orifilesize AS NUMERIC)) / 1024 / 1024 / 1024 AS NUMERIC(18, 3)) FROM srm23.'
		+ @db + '_review.dbo.reviewedoc as r with(nolock) INNER JOIN srm23.'
		+ @db + '_review.dbo.userviewdoc as v ON r.docid = v.docid WHERE UVID = ' + @view
		+ ' SELECT ''doccount'' = COUNT(*) FROM srm23.'
		+ @db + '_review.dbo.reviewedoc as r INNER JOIN srm23.'
		+ @db + '_review.dbo.userviewdoc as v ON r.DocID = v.DocID WHERE UVID = ' + @view
		+ ' SELECT ''pagecount_process'' = SUM(tiffpagecount) FROM srm26.'
		+ @db + '.dbo.edocoperations e INNER JOIN srm23.'
		+ @db + '_review.dbo.UserViewDoc v ON e.docid = v.DocID WHERE UVID = ' + @view
		+ ' SELECT ''pagecount_delivery'' = SUM(tifftotalpages) FROM srm23.'
		+ @db + '_review.dbo.deliverydoc as d INNER JOIN srm23.'
		+ @db + '_review.dbo.UserViewDoc as v ON d.docid = v.DocID WHERE UVID = ' + @view
		+ ' SELECT ''first_begdoc_r'' = min(edr_begbates), ''last_enddoc_r'' = max(edr_endbates) FROM srm23.'
		+ @db + '_review.dbo.reviewedoc as r INNER JOIN srm23.'
		+ @db + '_review.dbo.userviewdoc v ON r.docid = v.docid WHERE uvid = ' + @view
		+ ' SELECT c_firstname, c_lastname, ''count'' = COUNT(*) FROM srm23.'
		+ @db + '_review.dbo.ReviewEDoc as r INNER JOIN srm23.'
		+ @db + '_review.dbo.UserViewDoc as v ON r.DocID = v.DocID WHERE UVID = ' + @view
		+ ' GROUP BY C_FirstName,C_LastName'
		+ ' SELECT DeliveryUVID, foldervolumeprefix, foldervolumeindexlength, foldervolumeindex FROM srm23.'
		+ @db + '_review.dbo.delivery WHERE deliveryuvid = ' + @view

	EXECUTE (@sql)
END