

alter database [advwork]
modify file(
	name = AdventureWorksLT2008_Data
	,newname = advworklt
	,filename='c:\mydb\data\advworklt_data.mdf'
)

alter database [advworklt]
modify file(
	name  = advworkltlog
	,filename='c:\mydb\log\advworklt_log.ldf'
)

use master
alter database advworklt
set online



select * from sys.master_files


create database advworkdw
on(
	name = adworkdwmdf
	,filename='c:\mydb\data\advworkdw_data.mdf'
)
log on(
	name = advworkdwlog
	,filename='c:\mydb\log\advworkdw_log.ldf'
)
for attach

