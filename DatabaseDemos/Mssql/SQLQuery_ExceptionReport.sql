/*
VP Exception report

Doc ID	Original File Name	Original Extension	File ID Description	Slipsheet Reason

LAW

"BegDoc#","DocExt","EDFolder","Filename","SRM_Error Description"
*/

select 'Volume' = srm_exportvolume,BegDoc#, [Path], [Filename], Docext,
FileDescription, [SRM_Error Description] from tbldoc with(nolock)
where srm_exportvolume = 'ctrl001'
and [SRM_Error Description] is not null
order by [SRM_Error Description], begdoc#
