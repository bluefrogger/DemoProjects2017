
/*
Suffix starting on 2nd page notes.
&[SRM_DOCID]_&[0000]&[0001]
*/


/*Remove _0001 begdoc enddoc

update tblDoc
set begDoc# = replace(begdoc#,'_0001',''), enddoc# = replace(enddoc#,'_0001','')
where SRM_Hit_Fam = 1

SELECT begDoc#
	,endDoc#
	,substring(begDoc#, 0, len(begDoc#) - charindex('.', reverse(begDoc#)) + 1)
	,substring(endDoc#, 0, len(endDoc#) - charindex('.', reverse(endDoc#)) + 1)
	 + substring(endDoc#, len(endDoc#) - charindex('_', reverse(endDoc#)) + 1, len(endDoc#) - 1)
FROM tblDoc


/*Remove _0001 uid*/

Update tblPage set UID = replace(UID,'_0001','')
from tblPage
left outer join tblDoc on tblPage.id = tblDoc.id
where SRM_Hit_Fam = 1

SELECT uid
	,substring(uid, 0, len(uid) - charindex('.', reverse(uid)) + 1)
	+ substring(uid, len(uid) - charindex('_', reverse(uid)) + 1, len(uid) - 1)
FROM tblPage INNER JOIN tbldoc ON tblpage.id = tbldoc.id
WHERE srm_exportvolume = 'CQG121'
