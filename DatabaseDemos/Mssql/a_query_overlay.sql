
DupStatus

Count

N

20410

P

14585

P(attach)

9429

 	44424

match now
Alex Yoo 4:33 PM
rat basterd
Andy Saengsawat 4:34 PM
lol
that's why i'm andy..lol
Andy Saengsawat 4:39 PM
try this query so you will get 34,995 docs and another missing 9,429 are attachments of 'P'



select a.begdoc,a.SourceFileName,b.path from 
( 
select begdoc , 
LEFT(SourceFileName,LEN(SourceFileName) - 1) AS SourceFileName 
FROM (SELECT begdoc, 
(SELECT SourceFileName + '; ' AS [text()] 
FROM dbo.ILL031011_Overlay AS internal -- Change Table name 
WHERE internal.begdoc = begdoc.begdoc 
group by SourceFileName 
FOR xml PATH ('') 
) AS SourceFileName 
FROM ( SELECT begdoc 
FROM dbo.ILL031011_Overlay -- Change Table name 
GROUP BY begdoc ) AS begdoc) AS pre_trimmed 
--order by begdoc , SourceFileName 
)A inner join ( 

select begdoc , 
LEFT(path,LEN(path) - 1) AS path 
FROM (SELECT begdoc, 
(SELECT path + '; ' AS [text()] 
FROM dbo.ILL031011_Overlay AS internal -- Change Table name 
WHERE internal.begdoc = begdoc.begdoc 
group by path 
FOR xml PATH ('') 
) AS path 
FROM ( SELECT begdoc 
FROM dbo.ILL031011_Overlay -- Change Table name 
GROUP BY begdoc ) AS begdoc) AS pre_trimmed 
) b on a.begdoc = b.begdoc 

Alex Yoo 4:39 PM
ok
Andy Saengsawat 4:40 PM
i'm almost done
