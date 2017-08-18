
use dbzoo

create login zoologin 
with password = 'zookeeper'

create user zoouser 
for login zoologin

alter user zoouser 
with default_schema = dbo

create server role zoosrvrole 
authorization zoologin

alter server role dbcreator
add member zoologin



create role zoorole
authorization zoouser

alter role zoorole
add member zoouser

exec sp_addrolemember 'db_owner', zoouser

select * from  sys.dm_os_performance_counters

