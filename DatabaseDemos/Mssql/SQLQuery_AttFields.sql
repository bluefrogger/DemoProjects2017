
; with  ExportingDocs  as
(
select ID, AttachPID,DocID,srm_docid,
( select MIN(DocID) from tblDoc where AttachPID <> 0
and AttachPID = d.AttachPID
) as  MinDocID , ( select max(DocID) from tblDoc where AttachPID <> 0
and AttachPID = d.AttachPID
) as  MaxDocID 
 from 
tblDoc D with(nolock)
where AttachPID <> 0
)

select  ID ,AttachPID, SRM_DocID,BegAtt =  
isnull(( SELECT TOP 1 SD.SRM_DocID   FROM ExportingDocs SD WITH (NOLOCK)  --- Change ID
               INNER JOIN ExportingDocs SUB WITH (NOLOCK) on SD.DocID = ISNULL(SUB.MinDocID, SUB.DocID) 
               WHERE SUB.ID  = Doc.ID   
),''),
EndAtt = 
          isnull((SELECT TOP 1 SD.SRM_DocID  FROM ExportingDocs SD WITH (NOLOCK)  --- Change ID 
              INNER JOIN ExportingDocs SUB WITH (NOLOCK) on SD.DocID = ISNULL(SUB.MaxDocID, SUB.MinDocID) 
               WHERE SUB.ID  = Doc.ID   
               ),'')
,DocID, SRM_RecType
from tblDoc as Doc with(nolock)
where iim001041_hit_fam = 1 -- Change this 
order by DocID 

