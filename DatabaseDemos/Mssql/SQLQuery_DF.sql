
use ms092

; WITH CTE as (
select ID,AttachPID,DOCID,SRM_RecType , DupStatus,Filename,DocExt,AttachLvl,
Case When AttachLvl = 0 
then coalesce (DateSent, DateRcvd, DateAppStart , DateAppEnd)
else coalesce (DateSent, DateRcvd, DateAppStart , DateAppEnD,DateLastMod, DateCreated, DateLastPrnt , DateAccessed) 
End as DocDate ,MS092005_DocDate,MS092005_DocDateTime
,MS092005_InDate,MS092005_InDate_fam
from tblDoc with(nolock)
where EDSessionID in (3,4) and DupStatus <>'G'
--order by DocID 
)
Select * from CTE 
--where MS092005_DocDate
--  between '1/1/2010' 
--   and '12/1/2011'
order by DocID
