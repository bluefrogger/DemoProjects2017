

SELECT Column1
FROM Table1
WHERE Column1 COLLATE Latin1_General_CS_AS = 'casesearch'

+char(094)+char(124)+char(094)+
+char(254)+char(020)+char(254)+


select  char(094)+ cast(begdoc# as nvarchar(max))
	+char(094)+char(124)+char(094)+ cast(enddoc# as nvarchar(max))
	+char(094)+char(124)+char(094)+ cast(PGCOUNT as nvarchar(max))
	+char(094)+char(124)+char(094)+ cast(replace([path],'IRR010001\','') as nvarchar(max))
	+char(094)+char(124)+char(094)+ cast([FILENAME] as nvarchar(max))+char(094)
from tbldoc with(nolock)
order by [path], BegDoc#
