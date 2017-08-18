
select char(254)+begdoc#+char(254)+char(020)+char(254)
+enddoc#+char(254)+char(020)+char(254)
+srm_begattach+char(254)+char(020)+char(254)
+srm_endattach+char(254)+char(020)+char(254)
+cast(pgcount as nvarchar(32))+char(254)+char(020)+char(254)
+cast(srm_ocrpath as nvarchar(255))+char(254)
from tbldoc with(nolock)
where scba001001_exportbatch_1 = 1
order by begdoc#