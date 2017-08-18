
create database advwork
on (filename = 'C:\mydb\master\AdventureWorksLT2012_Data.mdf')
	,(filename = 'C:\mydb\log\AdventureWorksLT2012_log.ldf')
for attach;

GO

restore filelistonly
from disk = 'C:\mydb\master\AdventureWorksLT2012_Data.mdf'

create database dbzoo
on primary(
	name=zoomaster
	,filename='c:\mydb\master\zoomaster.mdf'
)
,filegroup fgzoocurrent(
	name=zoodata01
	,filename = 'c:\mydb\data\zoodata01.ndf'	
)
,(
	name=zoodata02
	,filename = 'c:\mydb\data\zoodata02.ndf'
)
,filegroup fgzooarchive(
	name=zooarchive
	,filename='c:\mydb\archive\zooarchive.ndf'
)
log on(
	name=zoolog
	,filename='c:\mydb\log\zoolog.ldf'
)

create table tblmammal(
	id int
	,species varchar(20)
)
on fgzoocurrent

use dbzoo

insert tblmammal
values(1,'gazelle')
	,(2,'zebra')
	,(3,'antelope')

use master
backup log model
to disk='c:\mydb\backup\model.ldf'

