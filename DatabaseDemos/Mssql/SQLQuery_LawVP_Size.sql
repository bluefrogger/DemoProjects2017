
----Law Extracted size
SELECT CAST(CAST(SUM(CAST(filesize AS NUMERIC)) / 1024 / 1024 / 1024 AS NUMERIC(18, 3)) AS VARCHAR) + ' GB'
FROM tbldoc
WHERE srm_exportvolume = 'BH045024'
	AND id = attachpid
	OR srm_exportvolume = 'BH045024'
	AND attachpid = 0;


----Law Counts
SELECT srm_wave
	,srm_exportvolume
	,COUNT(*)
FROM tbldoc
GROUP BY srm_wave
	,srm_exportvolume;

SELECT COUNT(*)
FROM tbldoc
WHERE srm_exportvolume = 'VOF-N-EREV004';

SELECT COUNT(*)
FROM tblpage
INNER JOIN tbldoc ON tblpage.id = tbldoc.id
WHERE srm_exportvolume = 'VOF-N-EREV004';

SELECT MIN(begdoc#)
	,MAX(enddoc#)
FROM tbldoc
WHERE srm_exportvolume = 'VOF-N-EREV004';

SELECT NAME
	,custodianid
	,COUNT(*) AS 'count'
FROM tbldoc
INNER JOIN tblcustodians ON custodianid = tblcustodians.id
WHERE srm_exportvolume = 'VOF-N-EREV004'
GROUP BY NAME
	,custodianid
ORDER BY NAME
	,custodianid;

WITH CTE
AS (
	SELECT id
		,AttachPID
	FROM tbldoc
	WHERE srm_wave = 'ATest001'
		AND attachpid = 0
	
	UNION ALL
	
	SELECT b.id
		,b.AttachPID
	FROM tbldoc a
	INNER JOIN tbldoc b ON a.id = b.attachpid
	WHERE a.srm_wave = 'ATest001'
		AND a.attachpid <> 0
	)
SELECT *
FROM cte
ORDER BY attachpid
	,id;

----VP Extracted Size
SELECT CAST(SUM(CAST(edfs_orifilesize AS NUMERIC)) / 1024 / 1024 / 1024 AS NUMERIC(18, 3))
FROM reviewedoc r
INNER JOIN userviewdoc c ON r.docid = c.docid
WHERE r.docid = ed_basedocid
	AND UVID = 9;

----VP Counts
SELECT COUNT(*)
FROM ReviewEDoc r
INNER JOIN UserViewDoc u ON r.DocID = u.DocID
WHERE UVID = 67;

SELECT SUM(TIFftotalpages)
FROM DeliveryDoc d
INNER JOIN UserViewDoc u ON d.DocID = u.DocID
WHERE UVID = 67;

SELECT edfs_orifileextension
	,COUNT(*)
FROM reviewedoc r
INNER JOIN userviewdoc u ON r.docid = u.docid
WHERE uvid = 15164
GROUP BY edfs_orifileextension;

SELECT SUM(tiffpagecount)
--select count(*)
FROM srm26.p00162.dbo.edocoperations e
INNER JOIN UserViewDoc u ON e.docid = u.DocID
WHERE UVID = 15356;

SELECT CAST(SUM(CAST(orifilesize AS NUMERIC)) / 1024 / 1024 / 1024 AS NUMERIC(18, 3))
FROM srm26.p00162.dbo.edocfilesystem f
INNER JOIN UserViewDoc u ON f.docid = u.DocID
WHERE UVID = 15356;

SELECT MIN(beginbates)
	,MAX(endbates)
FROM DeliveryDoc d
INNER JOIN UserViewDoc u ON d.DocID = u.DocID
WHERE UVID = 67;

SELECT c_firstname
	,C_lastname
	,COUNT(*)
FROM ReviewEDoc r
INNER JOIN UserViewDoc u ON r.DocID = u.DocID
WHERE UVID = 67
GROUP BY C_FirstName
	,C_LastName;

SELECT DeliveryUVID
	,foldervolumeprefix
	,foldervolumeindexlength
	,foldervolumeindex
FROM delivery;

SELECT TOP 10 *
FROM UserViewHeader
WHERE descr LIKE '%IFF0235%';

