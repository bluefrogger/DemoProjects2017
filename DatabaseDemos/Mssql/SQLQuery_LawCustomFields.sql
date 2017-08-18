/*ED_Source*/
SELECT
	--update tbldoc set srm_title_subj =
	CASE 
		WHEN title IS NULL
			THEN CASE 
					WHEN subject IS NOT NULL
						THEN subject
					ELSE NULL
					END
		ELSE CASE 
				WHEN subject IS NOT NULL
					THEN title + '; ' + subject
				ELSE title
				END
		END
FROM tblDoc
WHERE iim001030_hit_fam = 1;
GO

SELECT *
FROM tblEDSources;

SELECT SourcePath
	,SourceFileName
	,sourcefile
	,
	--update tbldoc set srm_edsource =
	CASE 
		WHEN SourceFileName IS NULL
			THEN SourcePath
		ELSE sourcepath + sourcefilename
		END
FROM tblDoc d with(nolock)
INNER JOIN tblEDSources s with(nolock) ON d.EDSourceID = s.ID
WHERE iim001030_hit_fam = 1;

SELECT SourcePath
	,SourceFileName
	,REPLACE(CAST(srm_sourcefile AS NVARCHAR(max)), 'S:\Irell Manella\IM001005_Part2\IM2086E012\', '')
	,srm_edsource
--update tbldoc set srm_edsource = 
--replace(cast(srm_edsource as nvarchar(max)),'S:\Irell Manella\IM001005_Part2\IM2086E012\','')
FROM tblDoc d
INNER JOIN tblEDSources s ON d.EDSourceID = s.ID
WHERE iim001030_hit_fam = 1;

/*SourceFile*/
SELECT COUNT(*)
FROM tblDoc
--update tbldoc set srm_sourcefile = sourcefile
WHERE iim001030_hit_fam = 1;

SELECT NAME
	,CAST(srm_sourcefile AS NVARCHAR(max))
	,REPLACE(CAST(srm_sourcefile AS NVARCHAR(max)), '\\prod-cfs-data\eSource\Irell Manella\IM001005\IM2086E039\', '')
--update tbldoc set srm_sourcefile = 
--REPLACE(cast(srm_sourcefile as nvarchar(max)),
--'\\prod-cfs-data\eSource\Irell Manella\IM001005\IM2086E039\','')
FROM tblDoc d WITH (NOLOCK)
INNER JOIN tblFolders f WITH (NOLOCK) ON d.EDFolderID = f.ID
WHERE iim001030_hit_fam = 1
GROUP BY NAME
	,CAST(srm_sourcefile AS NVARCHAR(max));

/*ED_Folder*/
SELECT *
FROM tblFolders;

SELECT distinct NAME
FROM tblDoc d WITH (NOLOCK)
INNER JOIN tblFolders f WITH (NOLOCK) ON d.EDFolderID = f.ID
WHERE iim001030_hit_fam = 1


SELECT NAME
	,cast(srm_edfolder AS NVARCHAR(max))
	,substring(NAME, charindex('\', NAME, charindex('\', NAME, charindex('\', NAME, charindex('\', NAME, 0) + 1) + 1) + 1) + 1, LEN(NAME))
--update tbldoc set srm_edfolder = substring(name,charindex('\',name,charindex('\',name,charindex('\',name,charindex('\',name,0)+1)+1)+1)+1,LEN(name))
FROM tblDoc d
INNER JOIN tblFolders f ON d.EDFolderID = f.ID
WHERE iim001030_hit_fam = 1
GROUP BY NAME
	,cast(srm_edfolder AS NVARCHAR(max))

SELECT substring(NAME, 0, charindex('\', NAME, charindex('\', NAME, charindex('\', NAME, charindex('\', NAME, 0) + 1) + 1) + 1) + 1)
--update tbldoc set srm_edfolder = substring(name,0,charindex('\',name,charindex('\',name,charindex('\',name,charindex('\',name,0)+1)+1)+1)+1)
FROM tblDoc d
INNER JOIN tblFolders f ON d.EDFolderID = f.ID
WHERE iim001030_hit_fam = 1
GROUP BY substring(NAME, 0, charindex('\', NAME, charindex('\', NAME, charindex('\', NAME, charindex('\', NAME, 0) + 1) + 1) + 1) + 1)

/*MailStore*/
SELECT srm_edsource
	,srm_mailstore
FROM tblDoc
--update tbldoc set srm_mailstore = srm_edsource
WHERE iim001030_hit_fam = 1;

;with ctea (edsource)
as
(SELECT 
	--update tbldoc set srm_edsource =
    CASE 
		WHEN SourceFileName IS NULL
			THEN SourcePath
		ELSE sourcepath + sourcefilename
		END
FROM tblDoc d with(nolock)
INNER JOIN tblEDSources s with(nolock) ON d.EDSourceID = s.ID
where ms092005_indate_fam = 1)
select edsource from ctea
group by edsource


SELECT DISTINCT CASE 
		WHEN SourceFileName IS NULL
			THEN SourcePath
		ELSE sourcepath + sourcefilename
		END
FROM tblDoc d WITH (NOLOCK)
INNER JOIN tblEDSources s WITH (NOLOCK) ON d.EDSourceID = s.ID
WHERE ms092005_indate_fam = 1

