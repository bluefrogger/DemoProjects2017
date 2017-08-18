
;with cte1 as 
(
	select 
		srm_docid,docid,attachlvl,id,attachpid
		,(
			select min(docid)
			from tbldoc with(nolock)
			where srm_exportvolume = 'ctrl001'
			and attachpid = main.attachpid
		) as mindocid
		,(
			select max(docid)
			from tbldoc with(nolock)
			where srm_exportvolume = 'ctrl001'
			and attachpid = main.attachpid
		) as maxdocid
	from tbldoc as main with(nolock)
)
update main_2
	set SRM_IMGBEG_ATT =
		isnull((
		select min(fam.srm_docid) from cte1 fam with(nolock)
		inner join cte1 sub with(nolock) 
			on fam.docid = isnull(sub.mindocid,sub.docid)
		where sub.docid = main_2.docid
		),'')
	,srm_imgend_att =
		isnull((
		select min(fam.srm_docid) from cte1 fam with(nolock)
		inner join cte1 sub with(nolock) 
			on fam.docid = isnull(sub.maxdocid,sub.docid)
		where sub.docid = main_2.docid
	),'')
from tbldoc as main_2 with(nolock)
where srm_exportvolume = 'ctrl001'

select srm_docid,enddoc#,attachlvl,id,attachpid
	,isnull((
		select min(fam.srm_docid) from cte1 fam with(nolock)
		inner join cte1 sub with(nolock) 
			on fam.docid = isnull(sub.mindocid,sub.docid)
		where sub.docid = main_2.docid
	),'') as begatt
	,isnull((
		select min(fam.srm_docid) from cte1 fam with(nolock)
		inner join cte1 sub with(nolock) 
			on fam.docid = isnull(sub.maxdocid,sub.docid)
		where sub.docid = main_2.docid
	),'') as endatt
from tbldoc as main_2 with(nolock)
where srm_exportvolume = 'ctrl001'
order by docid

USE ms108

;with cte_2 as
(
	select
		docid
		,attachlvl
		,id
		,attachpid
		,ATTNO = (row_number() over(partition by attachpid order by docid) - 1)
		,srm_attach_no
	from tbldoc with(nolock)
	where srm_exportvolume = 'ctrl001'
	and attachpid <> 0
)
--update cte_2 set srm_attach_no = attno