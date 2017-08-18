
/*Wave Volume Info*/

select srm_wave, srm_exportvolume, count(*) from tbldoc with(nolock)
group by srm_wave, srm_exportvolume


/*Volume Count*/

select count(*) from tbldoc with(nolock)
where srm_wave = 'ms095002'
and (srm_exclude = 0 or srm_exclude is null)

/*Duplicate Error Status*/

select docext, srm_exclude, [srm_error status], [srm_error description], count(*) from tbldoc
where srm_wave = 'ms095002'
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
Where Srm_Wave = 'ms095002'
And Docext Like 'xls%'
And ([Srm_Error Status] = 0 Or [Srm_Error Status] Is Null)
And (Srm_Exclude = 0 Or Srm_Exclude Is Null)
Group By Textxstatus, Textpstatus,Tiffstatus, Ocrstatus


/*Image Tiff OCR Status*/

select docext, tiffstatus, ocrstatus, COUNT(*)
from tblDoc with(nolock)
where (SRM_Exclude is null or SRM_Exclude = 0)
and ([SRM_Error Status] is null or [SRM_Error Status] = 0)
and (DocExt like 'tif%' or DocExt like 'jp%' or DocExt = 'bmp' or DocExt = 'gif' or DocExt = 'png')
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

--plug requested info and get rid of angled brackets.

SELECT tblDoc.<identifier goes here>, PgCount, ImagesCount = count(pkey)
FROM tblDoc inner join tblPage on tblDoc.ID = tblpage.id
WHERE <filter condition goes here>
GROUP by tblDoc.<identifier goes here>, pgCount
HAVING (pgCount - count(pkey)) <> 0  
ORDER BY tblDoc.<identifier goes here>

UNION ALL

--plug requested info and get rid of angled brackets.

SELECT tblDoc.<identifier goes here>, PgCount, '0' 
FROM tblDoc left join tblPage on tblDoc.ID = tblpage.id
WHERE <Filter goes here> and tblpage.ID is null
