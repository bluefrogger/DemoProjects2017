/*
https://www.brentozar.com/archive/2013/09/transactional-replication-change-tracking-data-capture/
http://www.codeproject.com/Articles/715550/SQL-Server-Replication-Step-by-Step
https://msdn.microsoft.com/en-us/library/ms151788.aspx
https://msdn.microsoft.com/en-us/library/ms174958.aspx

https://mattsql.wordpress.com/2012/05/15/setting-up-transactional-replication-using-t-sql/
*/

--Step 1: Set up a shared folder for snapshots.

--Step 2: Configure the distributor and publisher:

use master
exec sp_adddistributor @distributor = N'AlexY10'
	--, @password = N''
GO
exec sp_adddistributiondb @database = N'distribution'
	, @data_folder = N'C:\SQL\Data'
	, @log_folder = N'C:\SQL\Log'
	, @log_file_size = 2
	, @min_distretention = 0
	, @max_distretention = 72
	, @history_retention = 48
	, @security_mode = 1
GO

use [distribution] 

--if (not exists (
--		select * 
--		from sysobjects 
--		where name = 'UIProperties' and type = 'U ')) 
--	create table UIProperties(id int)

--if (exists (
--		select * 
--		from ::fn_listextendedproperty('SnapshotFolder'
--			, 'user'
--			, 'dbo'
--			, 'table'
--			, 'UIProperties'
--			, null, null))) 
--	EXEC sp_updateextendedproperty N'SnapshotFolder'
--		, N'C:\MSSQL\SQL_Share'
--		, 'user'
--		, dbo
--		, 'table'
--		, 'UIProperties' 
--else 
--	EXEC sp_addextendedproperty N'SnapshotFolder'
--		, N'C:\MSSQL\SQL_Share'
--		, 'user'
--		, dbo
--		, 'table'
--		, 'UIProperties'
--GO

exec sp_adddistpublisher @publisher = N'AlexY10'
	, @distribution_db = N'distribution'
	, @security_mode = 1
	, @working_directory = N'\\AlexY10\C$\SQL\MSSQL12.MSSQLSERVER\MSSQL\repldata\unc'
	, @trusted = N'false'
	, @thirdparty_flag = 0
	, @publisher_type = N'MSSQLSERVER'
GO
--Step 3: Configure a database for replication, create a publication,  and add an article:

use Publisher
exec sp_replicationdboption 
	@dbname = N'Publisher'
	, @optname = N'publish'
	, @value = N'true'
GO

use [AdventureWorks2008]
exec sp_addpublication @publication = N'AW_products'
	, @sync_method = N'concurrent'
	, @retention = 0
	, @allow_push = N'true'
	, @allow_pull = N'true'
	, @allow_anonymous = N'false'
	, @enabled_for_internet = N'false'
	, @snapshot_in_defaultfolder = N'true'
	, @compress_snapshot = N'false'
	, @ftp_port = 21
	, @allow_subscription_copy = N'false'
	, @add_to_active_directory = N'false'
	, @repl_freq = N'continuous'
	, @status = N'active'
	, @independent_agent = N'true'
	, @immediate_sync = N'false'
	, @allow_sync_tran = N'false'
	, @allow_queued_tran = N'false'
	, @allow_dts = N'false'
	, @replicate_ddl = 1
	, @allow_initialize_from_backup = N'false'
	, @enabled_for_p2p = N'false'
	, @enabled_for_het_sub = N'false'
GO

exec sp_addpublication_snapshot @publication = N'AW_products'
	, @frequency_type = 1
	, @frequency_interval = 1
	, @frequency_relative_interval = 1
	, @frequency_recurrence_factor = 0
	, @frequency_subday = 8
	, @frequency_subday_interval = 1
	, @active_start_time_of_day = 0
	, @active_end_time_of_day = 235959
	, @active_start_date = 0
	, @active_end_date = 0
	, @job_login = null
	, @job_password = null
	, @publisher_security_mode = 1

use [AdventureWorks2008]
exec sp_addarticle @publication = N'AW_products'
	, @article = N'Product'
	, @source_owner = N'Production'
	, @source_object = N'Product'
	, @type = N'logbased'
	, @description = null
	, @creation_script = null
	, @pre_creation_cmd = N'drop'
	, @schema_option = 0x000000000803509F
	, @identityrangemanagementoption = N'manual'
	, @destination_table = N'Product'
	, @destination_owner = N'Production'
	, @vertical_partition = N'false'
	, @ins_cmd = N'CALL sp_MSins_ProductionProduct'
	, @del_cmd = N'CALL sp_MSdel_ProductionProduct'
	, @upd_cmd = N'SCALL sp_MSupd_ProductionProduct'
GO
--Step 4: Backup the database on the publisher and restore to the subscription instance.
--Step 5: Configure a subscription (because I am creating a push subscription this script should be run on the publisher).

use [AdventureWorks2008]
exec sp_addsubscription @publication = N'AW_pub'
	, @subscriber = N'sslmattb2\INST2'
	, @destination_db = N'AW_products'
	, @subscription_type = N'Push'
	, @sync_type = N'automatic'
	, @article = N'all'
	, @update_mode = N'read only'
	, @subscriber_type = 0

exec sp_addpushsubscription_agent @publication = N'AW_pub'
	, @subscriber = N'sslmattb2\INST2'
	, @subscriber_db = N'AW_products'
	, @job_login = N'NT AUTHORITY\SYSTEM'
	, @job_password = null
	, @subscriber_security_mode = 1
	, @frequency_type = 64
	, @frequency_interval = 0
	, @frequency_relative_interval = 0
	, @frequency_recurrence_factor = 0
	, @frequency_subday = 0
	, @frequency_subday_interval = 0
	, @active_start_time_of_day = 0
	, @active_end_time_of_day = 235959
	, @active_start_date = 20120514
	, @active_end_date = 99991231
	, @enabled_for_syncmgr = N'False'
	, @dts_package_location = N'Distributor'
GO
/*Basic transactional replication is now running. In a future post I’ll look at monitoring 
and administering the replication environment.
*/

