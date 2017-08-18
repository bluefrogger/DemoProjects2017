
select iim001023_nondupe_fam, iim001023_nondup_fam, count(*) from tbldoc with(nolock)
group by iim001023_nondupe_fam, iim001023_nondup_fam

select count(*) from tbldoc
--update tbldoc set iim001023_nondup_fam = iim001023_nondupe_fam
where iim001023_nondupe_fam = 1

SELECT a.id, 
       b.id 
--update IIM001..tblDoc set IIM001023_NonDupe = 1 --Change database when you update---
FROM   iim001..iim001023_globdd_4custs_unique a --Base database No Change--
       INNER JOIN IIM001..tbldoc b WITH(nolock) --Change database when you update--
               ON a.id = b.id 
WHERE  db = 'DB_001' --- Changes DB name -> DB_001 = IIM001 , DB_002 = IIM001_prt2 , DB_003 = IIM001_prt3 , DB_004_Edoc = IIM001_EDOCS -- 
       AND ( a.begdoc# IS NULL 
              OR a.srm_docid IS NULL )


SELECT a.id, 
       b.id 
--update c set IIM001023_NonDupe_Fam = 1 --Change database when you update---
FROM   iim001..iim001023_globdd_4custs_unique a --Base database No Change--
       INNER JOIN IIM001..tbldoc b WITH(nolock) --Change database when you update--
               ON a.id = b.id
		left join IIM001..tbldoc c WITH(nolock)
				on b.id = c.attachpid
WHERE  db = 'DB_001' --- Changes DB name -> DB_001 = IIM001 , DB_002 = IIM001_prt2 , DB_003 = IIM001_prt3 , DB_004_Edoc = IIM001_EDOCS -- 
       AND ( a.begdoc# IS NULL 
              OR a.srm_docid IS NULL )


select top 1000 id, attachpid from tbldoc
where attachpid <> 0



;with cte as (
select a.ID from  idm120_part3..tblDoc a with(nolock)
where a.IDM120026_Step3_hit = 1 and a.IDM120026_3Cust_NoDupe = 1
and SRM_SortDate between '11/30/2009' and '02/29/2012'
and AttachPID= 0
union all
select b.ID from 
(
select  distinct(AttachPID) as 'ID' from  idm120_part3..tblDoc a with(nolock)
where a.IDM120026_Step3_hit = 1 and a.IDM120026_3Cust_NoDupe = 1
and SRM_SortDate between '11/30/2009' and '02/29/2012'
and AttachPID <> 0)A  
inner join idm120_part3..tblDoc b on a.ID = b.AttachPID
)
select a.ID,b.IDM120026_Step3_hit ,IDM120026_Step3_hit_fam 
--into ##testttttt
--update idm120_part3..tblDoc set IDM120026_Step3_hit_fam = 1
from cte a
inner join idm120_part3..tblDoc b on a.ID = b.ID
where IDM120026_Step3_hit =1



select count(*) from tbldoc
where [IDM120026_Step_1_4_Hit] = 1
union all
select count(*) from tbldoc
where [IDM120026_Step_1_4_Hit_fam] = 1
union all
select count(*) from tbldoc
where [IDM120026_Step_1_4_Hit_fam] = 1
	and attachpid = 0
union all
select count(*) from
(
	select distinct(attachpid) as 'id' from tbldoc a with(nolock)
	where [IDM120026_Step_1_4_Hit_fam] = 1 and attachpid <> 0
) as A
	inner join tbldoc b on a.id = b.attachpid
