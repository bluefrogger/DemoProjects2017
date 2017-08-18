/*
https://msdn.microsoft.com/en-us/library/ms147302.aspx
*/
-- Install the Distributor and the distribution database.
-- Install the server MYDISTPUB as a Distributor using the defaults, including autogenerating the distributor password.
USE master
GO
-- Specify the Distributor name.
EXEC sp_adddistributor @distributor = N'AlexY10';
-- Create a new distribution database using the defaults, including using Windows Authentication.
-- Specify the distribution database.
EXEC sp_adddistributiondb @database = N'distribution'
	, @security_mode = 1

-- Create a Publisher and enable AdventureWorks2012 for replication.
-- Add MYDISTPUB as a publisher with MYDISTPUB as a local distributor and use Windows Authentication.
USE [distribution]
EXEC sp_adddistpublisher 
	@publisher = N'AlexY10'
	, @distribution_db = N'distribution'
	, @working_directory = N'\\AlexY10\C$\SQL\MSSQL12.MSSQLSERVER\MSSQL\repldata'
	, @security_mode = 1

--Step 3: Configure a database for replication, create a publication,  and add an article:
USE Publisher
GO
EXEC sp_replicationdboption 
	@dbname = N'Publisher'
	, @optname = N'publish'
	, @value = N'true'
GO

--Warning: The logreader agent job has been implicitly created and will run under the SQL Server Agent Service Account.
EXEC sp_addpublication 
	@publication = 'Publication'
	, @sync_method = 'concurrent'
	, @retention = 0
	, @allow_push = 'true'
	, @allow_pull = 'false'
	, @allow_dts = 'false'
	, @status = 'active';
EXEC sp_changepublication 
	@publication = 'Publication'
	, @property = 'status'
	, @value = 'active'

EXEC sp_addpublication_snapshot @publication = 'Publication'

EXEC sp_addarticle 
	@publication = 'Publication'
	, @article = 'Article'
	, @source_owner = 'dbo'
	, @source_object = 'ContactType'
	, @destination_owner = 'dbo'
	, @destination_table = 'ContactType'
	, @type = 'logbased'

--Subscriber
EXEC sp_addsubscription
	@publication = 'Publication'
	, @article = 'all'
	, @subscriber = 'AlexY10'
	, @subscription_type = 'push'
	, @subscriber_type = 0 --SQL Server Subscriber
	, @destination_db = 'Subscriber'
	, @dts_package_location = 'Distributor'

SELECT * FROM distribution.dbo.MSpublications AS ms
SELECT * FROM distribution.dbo.MSsubscriptions AS ms

EXEC sp_addpushsubscription_agent
	@Publication = 'Publication'
	, @subscriber = 'AlexY10'
	, @subscriber_db = 'Subscriber'
	, @dts_package_location = 'Distributor'
