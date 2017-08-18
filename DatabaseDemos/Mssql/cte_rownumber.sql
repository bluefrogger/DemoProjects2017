select top 10 beginbates, endbates, BeginAtt, endatt, TIFFTotalPages from deliverydoc
select 'DatabaseName' = db_name()
go

with bates_CTE (tiffpages, batescount)
as
(select tifftotalpages, cast(right(endbates,9) as int)-cast(right(beginbates,9) as int)+1
from deliverydoc where docid in
	(select docid from userviewdoc where uvid = 14817
	)
)

select tiffpages, batescount,
	'match' = case (tiffpages - batescount)
		when 0 then 'Good'
		else 'Bad' end
from bates_CTE
go

select 'attorder' = row_number() over(partition by beginatt order by beginbates),
	beginbates,endbates,beginatt, endatt
from deliverydoc where docid in
	(select docid from userviewdoc where uvid = 14817
	)
order by beginatt
go


select t.name, c.name from sys.tables t
inner join sys.columns c on t.object_id = c.object_id
where c.name like '%bates%'
order by t.name, c.name
go

EXEC sp_RENAME table_name.old_name, new_name, 'COLUMN'
go


; WITH cte
     AS (SELECT b.custodianid,
                Folder = 'Natives',
                SizeInB = Sum(edfs_orifilesize),
                SizeInKB = Sum(Cast(Round(( Cast(edfs_orifilesize AS
                                                 NUMERIC(15, 4))
                                            /
                                            1024 ), 3
                                    ) AS
                                                   DECIMAL(10, 3))),
                SizeInMB = Sum(Cast(Round(( Cast(edfs_orifilesize AS
                                                 NUMERIC(15, 4))
                                            /
                                            1024 /
                                            1024 ), 3) AS
                                                   DECIMAL(
                                                   10, 3)))
         FROM   dbo.reviewedoc A WITH(nolock)
                INNER JOIN dbo.custodian B WITH(nolock)
                        ON a.c_custodianid = b.custodianid
      --          INNER JOIN ##ViewDocID C WITH(nolock) -- Join to ##ViewDocID
                                    --ON A.docid = C.docid
				inner join userviewdoc c with(nolock) on a.docid = c.docid                                
         WHERE  custodianid in (1) and uvid = 3
                AND a.docid = a.ed_basedocid
         GROUP  BY b.custodianid)
SELECT a.custodianid,
       Custodian = '',
       folder,
       c.filecount,
       sizeinb,
       sizeinkb,
       sizeinmb,
       [sizeinmb(on disk)]            
FROM   cte a
       INNER JOIN (SELECT a.c_custodianid,
                          FileCount = Count(*),
                          'SizeInMB(ON Disk)' = Sum(Cast(
                          Round(( Cast(edfs_orifilesize
                                       AS NUMERIC(
                                       15, 4))
                                  / 1024 / 1024 ), 3) AS
                                                    DECIMAL(
                                                    10, 3)))
                   FROM   dbo.reviewedoc a WITH(nolock)
                          INNER JOIN dbo.custodian b WITH(nolock)
                                  ON a.c_custodianid = b.custodianid
                                      --INNER JOIN ##ViewDocID C WITH(nolock) -- Join to ##ViewDocID
                                      --ON A.docid = C.docid    
									  inner join userviewdoc c with(nolock) on a.docid = c.docid                                                                    
                   WHERE  custodianid in (1) and uvid = 3
                   GROUP  BY a.c_custodianid) C
               ON a.custodianid = c. c_custodianid  
