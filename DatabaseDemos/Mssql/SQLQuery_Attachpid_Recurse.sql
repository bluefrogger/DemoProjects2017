

/*Volume Count*/

select count(*) from tbldoc d with(nolock)
where d.attachpid in
(	select attachpid from tbldoc e with(nolock)
	where srm_wave = 'DLAC021005'
	and (srm_exclude = 0 or srm_exclude is null)
	and attachpid <> 0
)
or
(	srm_wave = 'DLAC021005' and attachpid = 0
	and (srm_exclude = 0 or srm_exclude is null)
)

;with t1 (count) as
(	select count(*) from tbldoc d with(nolock)
	where d.attachpid in
	(	select attachpid from tbldoc e with(nolock)
		where srm_wave = 'DLAC021005'
		and (srm_exclude = 0 or srm_exclude is null)
		and attachpid <> 0
	)
	Union all
	select count(*) from tbldoc d with(nolock)
	where srm_wave = 'DLAC021005' and attachpid = 0
	and (srm_exclude = 0 or srm_exclude is null)
)
select sum(count) from t1

/*Duplicate Error Status*/

select docext, srm_exclude, [srm_error status], [srm_error description], count(*) from tbldoc
where srm_wave = 'DLAC021005'
group by  docext, srm_exclude, [srm_error status], [srm_error description]
order by docext, srm_exclude, [srm_error status], [srm_error description]


/*Error Message*/

select errormsg,* from tbldoc with(nolock)
where srm_wave = 'ms095002'
and [srm_error status] = 1
and docext = 'pdf'
order by cast(errormsg as nvarchar(max))


/*Tiff OCR Status*/

Select Textxstatus, Textpstatus, Tiffstatus, Ocrstatus, Count(*) From Tbldoc
Where Srm_exportvolume = 'ehd003'
And ([Srm_Error Status] = 0 Or [Srm_Error Status] Is Null)
And (Srm_Exclude = 0 Or Srm_Exclude Is Null)
Group By Textxstatus, Textpstatus,Tiffstatus, Ocrstatus


/*Image Tiff OCR Status*/

select docext, tiffstatus, ocrstatus, COUNT(*)
from tblDoc
where (SRM_Exclude is null or SRM_Exclude = 0)
and ([SRM_Error Status] is null or [SRM_Error Status] = 0)
and (DocExt like 'tif%' or DocExt like '%jp' or DocExt = 'bmp' or DocExt = 'gif' or DocExt = 'png')
group by docext, TiffStatus, ocrstatus

/*Tiff OCR ErrorMessage*/
select docext,textxstatus,tiffstatus, ocrstatus, convert(nvarchar(max),errormsg), count(*) from tbldoc with(nolock)
where srm_wave = 'ms095002'
and (srm_exclude = 0 or srm_exclude is null)
and ([srm_error status] = 0 or [srm_error status] is null)
group by docext,textxstatus,tiffstatus, ocrstatus, convert(nvarchar(max),errormsg)

/*Numbering Check*/

select begdoc#
from tbldoc inner join tblPage
on tbldoc.id = tblpage.id
where dbo.tblDoc.srm_exportvolume like '%CL003%' and uid is null

/*Endorsement check*/

select begdoc#
from tbldoc inner join tblPage
on tbldoc.ID = tblpage.ID
where footer = 0 and dbo.tblDoc.srm_exportvolume like '%WPLV005%'
group by begdoc#

/*Page count match*/

select tblDoc.begdoc#, pgcount, count(pkey), CountMatch = 
case (pgCount - count(pkey))
WHEN 0 then 'Match'
ELSE 'Do Not Match'
END
from tblDoc inner join tblPage on tblDoc.ID = tblpage.id
where dbo.tblDoc.srm_exportvolume like '%CL003%'
group by tblDoc.begdoc#, pgCount
order by tblDoc.begdoc#


;

WITH cte
AS (
	SELECT a.ID
	FROM idm120_part3..tblDoc a WITH (NOLOCK)
	WHERE a.IDM120026_Step3_hit = 1
		AND a.IDM120026_3Cust_NoDupe = 1
		AND SRM_SortDate BETWEEN '11/30/2009'
			AND '02/29/2012'
		AND AttachPID = 0
	
	UNION ALL
	
	SELECT b.ID
	FROM (
		SELECT DISTINCT (AttachPID) AS 'ID'
		FROM idm120_part3..tblDoc a WITH (NOLOCK)
		WHERE a.IDM120026_Step3_hit = 1
			AND a.IDM120026_3Cust_NoDupe = 1
			AND SRM_SortDate BETWEEN '11/30/2009'
				AND '02/29/2012'
			AND AttachPID <> 0
		) A
	INNER JOIN idm120_part3..tblDoc b ON a.ID = b.AttachPID
	)
SELECT a.ID
	,b.IDM120026_Step3_hit
	,IDM120026_Step3_hit_fam
--into ##testttttt
--update idm120_part3..tblDoc set IDM120026_Step3_hit_fam = 1
FROM cte a
INNER JOIN idm120_part3..tblDoc b ON a.ID = b.ID
WHERE IDM120026_Step3_hit = 1


;WITH ShowMessage (STATEMENT,LENGTH)
AS (
	SELECT STATEMENT = CAST('I Like ' AS VARCHAR(300)), LEN('I Like ')
	
	UNION ALL
	
	SELECT CAST(STATEMENT + 'CodeProject! ' AS VARCHAR(300)), LEN(STATEMENT)
	FROM ShowMessage
	WHERE LENGTH < 300
	)
SELECT STATEMENT,LENGTH
FROM ShowMessage



select * from tblcustodians

