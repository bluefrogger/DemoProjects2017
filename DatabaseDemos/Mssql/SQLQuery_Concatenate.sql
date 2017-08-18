

GO

USE AlexTest;

select iim001026_priv_searchtext
--update iim001_edocs.dbo.tbldoc set iim001026_priv_searchtext = null
from iim001_edocs.dbo.tbldoc d inner join #edocs_list1_ns e on d.id = e.id
where IIM001026_Hit_Fam = 1


--create table IIM001026_IIM001_prt2_Priv (id int, searchtext nvarchar(max))
--create table #IIM001_prt2_Priv (id int, searchtext nvarchar(max))

select COUNT(*) from dbo.IIM001026_IIM001_prt2_Priv_List2_Sens
drop table IIM001026_IIM001_prt2_Priv_List2_Sens

insert into #IIM001_prt2_Priv
select * from dbo.IIM001026_IIM001_prt2_Priv_List2_Sens

insert into dbo.IIM001026_IIM001_prt2_Priv
SELECT ID , 
       LEFT( SearchText , LEN(SearchText) - 1
           )AS SearchText
  FROM( 
        SELECT ID , 
               ( 
			 SELECT SearchText + '; ' AS [text()]
				FROM dbo.#IIM001_prt2_Priv AS internal -- Change Table name
				WHERE internal.ID = ID.ID
				GROUP BY SearchText
				FOR XML PATH('')
               )AS SearchText
				FROM( 
				    SELECT ID
				    FROM dbo.#IIM001_prt2_Priv -- Change Table name
				    GROUP BY ID
				    )AS ID
      )AS pre_trimmed
  ORDER BY ID , SearchText


  select iim001026_priv_searchtext 
  --update iim001_prt2.dbo.tblDoc set iim001026_priv_searchtext = searchtext
  from iim001_prt2.dbo.tblDoc d 
  inner join alextest.dbo.IIM001026_IIM001_prt2_Priv p 
  on d.ID = p.id
  where iim001026_hit_fam = 1

select * from  alextest.dbo.IIM001026_IIM001_prt2_Priv
  
