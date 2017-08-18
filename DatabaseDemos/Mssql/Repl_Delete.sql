/*
	https://technet.microsoft.com/en-us/library/ms147921(v=sql.105).aspx
	https://www.mssqltips.com/sqlservertip/2710/steps-to-clean-up-orphaned-replication-settings-in-sql-server/
*/

USE msdb
GO
EXEC dbo.sp_delete_job @job_name = N'Agent history clean up: Distribution'
EXEC dbo.sp_delete_job @job_name = N'Distribution clean up: Distribution'
EXEC dbo.sp_delete_job @job_name = N'Expired subscription clean up'
EXEC dbo.sp_delete_job @job_name = N'Reinitialize subscriptions having data validation failures'
EXEC dbo.sp_delete_job @job_name = N'Replication agents checkup'
EXEC dbo.sp_delete_job @job_name = N'Replication monitoring refresher for Distribution.'
-- Stop all replication-related jobs. 
EXEC dbo.sp_stop_job @job_name = N'Agent history clean up: Distribution'
EXEC dbo.sp_stop_job @job_name = N'Distribution clean up: Distribution'
EXEC dbo.sp_stop_job @job_name = N'Expired subscription clean up'
EXEC dbo.sp_stop_job @job_name = N'Reinitialize subscriptions having data validation failures'
EXEC dbo.sp_stop_job @job_name = N'Replication agents checkup'
EXEC dbo.sp_stop_job @job_name = N'Replication monitoring refresher for Distribution.'
GO

--At each Subscriber on the subscription database, execute sp_removedbreplication to remove replication objects from the database. 
USE master
GO
USE Subscriber
EXEC sp_removedbreplication @dbname = N'Subscriber'
--At the Publisher on the publication database, execute sp_removedbreplication to remove replication objects from the database
USE Publisher
EXEC sp_removedbreplication @dbname = N'Publisher'

--IF the Publisher uses a remote Distributor, execute sp_dropdistributor.

USE master
EXEC sp_helpreplicationdboption @dbname = N'Publisher'
EXEC sp_helpreplicationdboption @dbname = N'Subscriber'
-- Remove the registration of the local Publisher at the Distributor.
EXEC sp_dropdistpublisher @publisher = 'AlexY10';
-- Delete the distribution database.
EXEC sp_dropdistributiondb @database = 'distribution';
-- Remove the local server as a Distributor.
EXEC sp_dropdistributor;
GO


USE Publisher
GO

EXEC sp_dropsubscription
    @publication = N'Publication'
    , @subscriber = N'AlexY10'--N'SubscriberServer' 
    , @destination_db = N'Subscriber'
    , @article = N'all';

USE Subscriber
GO

EXEC sp_subscription_cleanup
    @publisher = 'AlexY10'--N'PublisherServer'
    , @publisher_db = N'Publisher'
    , @publication = N'Publication';
GO


-- Disable replication db option
EXEC sp_replicationdboption @dbname = N'Publisher', @optname = N'publish', @value = N'false'
EXEC sp_replicationdboption @dbname = N'Subscriber', @optname = N'publish', @value = N'false'
GO

USE Publisher
-- Drop subscription
EXEC sp_dropsubscription @publication = N'Publication', @subscriber = N'AlexY10', @destination_db = N'Subscriber', @article = N'all'
-- Cleanup Subscription metadata
EXEC sp_subscription_cleanup @publisher = N'AlexY10', @publisher_db = N'Publisher', @publication = N'Publication'
-- Drop all replication objects on server
EXEC sp_removesrvreplication
GO
-- Desperate meaures
ALTER DATABASE Replicant SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE Replicant
GO

--https://www.mssqltips.com/sqlservertip/2710/steps-to-clean-up-orphaned-replication-settings-in-sql-server/

-- Connect Subscriber
use master
exec sp_helpreplicationdboption @dbname = 'Subscriber'--N'MyReplDB'
go
use Subscriber
EXEC sp_subscription_cleanup @publisher = N'AlexY10', @publisher_db = N'Publisher', @publication = N'Publication'
go
-- Connect Publisher Server
-- Drop Subscription
use Publisher
exec sp_dropsubscription @publication = N'Publication', @subscriber = N'all', @destination_db = N'Subscriber', @article = N'all'
go
-- Drop publication
exec sp_droppublication @publication = N'Publication'
-- Disable replication db option
exec sp_replicationdboption @dbname = N'Publisher', @optname = N'publish', @value = N'false'
exec sp_replicationdboption @dbname = N'Subscriber', @optname = N'publish', @value = N'false'
GO