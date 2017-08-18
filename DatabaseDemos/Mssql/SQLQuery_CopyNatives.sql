

create table MS095_natives (docid nvarchar(max))
drop table MS095_natives

bulk insert MS095_natives
from 'c:\ms095001_n_docid.txt'
with (
	fieldterminator = '',
	rowterminator = '\n'
)

select [NTV_PATH], begdoc#,
'copy "'+[NTV_PATH]+'" '+'"P:\MS\0095\03_WorkOrders\MS095001\Delivery\CTRL001\NATIVES\001\'+begdoc#+'.'+docext+'"'
FROM ms095.[dbo].[vw_Doc1]
where begdoc# not in
(
	select docid from MS095_natives
)
order by id


select begdoc#, b.docid, 
'copy "'+
 begdoc#+'.'+docext+'" '+'P:\MS\0095\03_WorkOrders\MS095001\Delivery\CTRL001\NATIVES\001\''
from tbldoc a with(nolock)
inner join MS095_natives b with(nolock) on a.begdoc# = b.docid
where srm_exportvolume = 'ctrl001'


select docid, replace(docid,'Conte','') from MS095_natives with(nolock)
--UPDATE MS095_natives set docid = replace(docid,'Conte','')
where docid not in
(
	select begdoc# from tbldoc with(nolock)
	where srm_exportvolume = 'ctrl001'
)

