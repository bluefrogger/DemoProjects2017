

drop table #temp002hdd
create table #temp004hdd (files nvarchar(max))

drop table #temp001net
create table #temp004net (files nvarchar(max))

bulk insert #temp003net
from '\\srm22\c$\pp10_003net.txt'
with
(
fieldterminator = '',
rowterminator = '\n'
)
go
select substring(files,67,len(files)) from #temp001net
select substring(files,46,len(files)) from #temp001net
select top 10 charindex('.', substring(files,46,len(files)),0) from #temp001net
select top 10 substring(substring(files,67,len(files)),0,charindex('.', substring(files,67,len(files)),0)) from #temp001net
select top 10 * from #temp001net
select substring(files,33,len(files)) from #temp001hdd


select iim001023_docid, [path], [filename], docext, [srm_error description] from tbldoc with(nolock)
select count(*) from tbldoc with(nolock)
--update tbldoc set srm_virus = 1
where iim001023_exportvolume = 'pp10_001'
and iim001023_docid in
(
select substring(substring(files,67,len(files)),0,charindex('.', substring(files,67,len(files)),0))
from #temp001net with(nolock)
where substring(files,67,len(files)) not in
(select substring(files,33,len(files)) from #temp001hdd)
)
go


select count(*) from #temp001net
select count(*) from #temp001hdd
select * from #temp002net where files not in
(select files from #temp002hdd)


--update tbldoc set srm_virus = 1
where iim001023_exportvolume = 'pp10_002'
and iim001023_docid in
(
select files,substring(substring(files,67,len(files)),0,charindex('.', substring(files,67,len(files)),0))
from #temp002net with(nolock)
where substring(files,67,len(files)) not in
(select substring(files,33,len(files)) from #temp002hdd)
)
go

select count(*) from #temp002net
select count(*) from #temp002hdd


--update tbldoc set srm_virus = 1
where iim001023_exportvolume = 'pp10_003'
and iim001023_docid in
(
select substring(substring(files,67,len(files)),0,charindex('.', substring(files,67,len(files)),0))
from #temp003net with(nolock)
where substring(files,67,len(files)) not in
(select substring(files,33,len(files)) from #temp003hdd)
)
go

select docext, iim001023_exportvolume,* from tbldoc
--update tbldoc set srm_virus = 1
where iim001023_docid = 'pp10_00282257'

;with acte (docid) as
(
select iim001023_docid
from tblDoc
where IIM001023_ExportVolume = 'pp10_001'
except
select docid from #temp5
)
select a.docid, RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),
nativepath = '\\prod-cfs-data\Cases\IIM001_prt2\$EDD\$NativeFiles\'+
left(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),2) + '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),3,2) + '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),5,2)+ '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),7,2)+'.ntv.'+d.DocExt
from acte a inner join tblDoc d
on a.docid = IIM001023_DOCID
order by a.docid


--update #temp5 set docid = REPLACE(docid,' PP','PP')


--truncate table #temp5

select MIN(docid), MAX(docid) from #temp

drop table #tempfile4
create table #tempfile6 (files nvarchar(max))

bulk insert #tempfile6
from 'c:\pp10_006files.txt'
with
(
fieldterminator = '',
rowterminator = '\n'
)
go




select textxstatus, COUNT(*) from tblDoc with(nolock)
where srm_wave = 'IIM001033'
group by TextXStatus


select _FTIndex, COUNT(*) from tblDoc with(nolock)
where srm_wave = 'IIM001033'
group by _FTIndex


 select begdoc#, enddoc#, SRM_BegBate_DOCID, SRM_BegDoc_Old,
 docid, SRM_DocID, SRM_DocID_Old, Title, [Subject], SRM_TITLE_SUBJ, email_subject
 from tblDoc with(nolock)
 where iim001030_hit_fam = 1
 order by SRM_BegBate_DOCID
 go
 
 select COUNT(*) from tbldoc
  --update tbldoc set srm_docid = docid
 where iim001030_hit_fam = 1
go

select 
--update tbldoc set srm_title_subj =
case when title IS NULL then
	case when [subject]is not null then [subject]
		else null end
	else case when [subject] is not null then title + '; ' + [subject]
		else title end
end
from tblDoc where iim001030_hit_fam = 1
go


select * from tblEDSources
select * from tblFolders

select SourcePath, SourceFileName, sourcefile,
--update tbldoc set srm_edsource =
case when SourceFileName IS null then SourcePath
	else sourcepath+sourcefilename end
from tblDoc d inner join tblEDSources s on d.EDSourceID = s.ID
where iim001030_hit_fam = 1


select SourcePath, SourceFileName, replace(cast(srm_sourcefile as nvarchar(max)),'S:\Irell Manella\IM001005_Part2\IM2086E012\',''), srm_edsource
--update tbldoc set srm_edsource = replace(cast(srm_edsource as nvarchar(max)),'S:\Irell Manella\IM001005_Part2\IM2086E012\','')
from tblDoc d inner join tblEDSources s on d.EDSourceID = s.ID
where iim001030_hit_fam = 1


select sourcePath
from tblDoc d with(nolock) inner join tblEDSources s with(nolock) on d.EDSourceID = s.ID
where iim001030_hit_fam = 1
group by sourcePath


select srm_wave, srm_exportvolume, SourceFile from tblDoc with(nolock)
--update tbldoc set srm_exportvolume = 'PP07_023'
where iim001030_hit_fam = 1
group by srm_wave, srm_exportvolume


select COUNT(*) from tblDoc
--update tbldoc set srm_sourcefile = sourcefile
where iim001030_hit_fam = 1


select name, cast(srm_sourcefile as nvarchar(max)), REPLACE(cast(srm_sourcefile as nvarchar(max)),'\\prod-cfs-data\eSource\Irell Manella\IM001005\IM2086E039\','')
--update tbldoc set srm_sourcefile = REPLACE(cast(srm_sourcefile as nvarchar(max)),'\\prod-cfs-data\eSource\Irell Manella\IM001005\IM2086E039\','')
from tblDoc d with(nolock) inner join tblFolders f with(nolock) on d.EDFolderID = f.ID
where iim001030_hit_fam = 1
group by name, cast(srm_sourcefile as nvarchar(max))

select name
from tblDoc d with(nolock) inner join tblFolders f with(nolock) on d.EDFolderID = f.ID
where iim001030_hit_fam = 1
group by name

 
select textxstatus,TiffStatus,ocrstatus, COUNT(*) from tblDoc with(nolock)
where iim001030_hit_fam = 1
group by TextXStatus,TiffStatus,ocrstatus

select 


select iim001030_begdoc from tblDoc
--update tbldoc set iim001030_begdoc = SRM_BegBate_DOCID
where iim001030_hit_fam = 1
order by iim001030_begdoc 


select BegDoc#,EndDoc#, iim001030_begdoc, IIM001030_enddoc, AttachLvl from tblDoc
--update tbldoc set iim001030_enddoc = iim001030_begdoc
where iim001030_hit_fam = 1
order by iim001030_begdoc


select srm_rectype from tblDoc
--update tbldoc set iim001030_enddoc = iim001030_begdoc
where iim001030_hit_fam = 1

select srm_edsource, srm_mailstore from tblDoc
--update tbldoc set srm_mailstore = srm_edsource
where iim001030_hit_fam = 1


;with acte (docid) as
(
select iim001030_begdoc
from tblDoc
where iim001030_hit_fam = 1
)
select a.docid, RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),
nativepath = '\\prod-cfs-data\Cases\IIM001_prt2\$EDD\$NativeFiles\'+
left(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),2) + '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),3,2) + '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),5,2)+ '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),7,2)+'.ntv.'+d.DocExt
from acte a inner join tblDoc d
on a.docid = 
order by a.docid



select srm_edsource,attachpid, attachlvl,[filename],iim001030_begdoc, RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),
nativepath = '\\prod-cfs-data\Cases\IIM001_prt2\$EDD\$NativeFiles\'+
left(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),2) + '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),3,2) + '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),5,2)+ '\'+
SUBSTRING(RIGHT('00000000' + CONVERT(nvarchar,d.id), 8),7,2)+'.ntv.'+d.DocExt
from tblDoc d
where d.ID in (2773265,2773268,2773262)
			   
select * from tblEDSources s inner join tblDoc d
on s.ID = d.EDSourceID
where d.ID in (2773265,2773268,2773262)

select AttachPID, AttachLvl,* from tblDoc where AttachPID = 2773262


select textxstatus,TiffStatus,ocrstatus, COUNT(*) from tblDoc with(nolock)
where iim001030_hit_fam = 1
group by TextXStatus,TiffStatus,ocrstatus


select name, sourcefilename, sourcefile, [filename], 
from tblDoc d inner join tblFolders f on d.EDFolderID = f.ID
inner join tblEDSources s on d.EDSourceID = s.ID
where iim001030_hit_fam = 1


select srm_sourcefile from tblDoc with(nolock)
where iim001030_hit_fam = 1
order by iim001030_begdoc
