/*
	https://msdn.microsoft.com/en-us/library/ms151797.aspx
*/

USE msdb 
GO  
EXEC dbo.sp_delete_job @job_name = N'Reinitialize subscriptions having data validation failures'
-- Stop all replication-related jobs. 
EXEC dbo.sp_stop_job @job_name = N'Agent history clean up: Distribution'
EXEC dbo.sp_stop_job @job_name = N'Distribution clean up: Distribution'
EXEC dbo.sp_stop_job @job_name = N'Expired subscription clean up'
EXEC dbo.sp_stop_job @job_name = N'Reinitialize subscriptions having data validation failures'
EXEC dbo.sp_stop_job @job_name = N'Replication agents checkup'
EXEC dbo.sp_stop_job @job_name = N'Replication monitoring refresher for Distribution.'
GO

-- remove replication objects from the database.
-- Disable the publication database.
USE master
GO
EXEC sp_removedbreplication N'Development'
EXEC sp_subscription_cleanup @publisher = N'Development', @publisher_db = N'Development'
EXEC sp_removedbreplication N'Replicant'
EXEC sp_removesrvreplication
GO

-- Drops subscriptions to a particular article, publication, or set of subscriptions on the Publisher. 
-- This stored procedure is executed at the Publisher on the publication database.

-- Connect Subscriber
:connect TestSubSQL1
use [master]
exec sp_helpreplicationdboption @dbname = N'Replicant'
GO

use Replicant
exec sp_subscription_cleanup @publisher = N'AlexY10', @publisher_db = N'Development', @publication = N'Development'
GO
ALTER DATABASE Replicant SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE Replicant
-- Connect Publisher Server
:connect TestPubSQL1

-- Drop Subscription
use Development
exec sp_dropsubscription @publication = N'Development', @subscriber = N'all', @destination_db = N'Replicant', @article = N'all'
GO

-- Drop publication
exec sp_droppublication @publication = N'Development'

-- Disable replication db option
exec sp_replicationdboption @dbname = N'Development', @optname = N'publish', @value = N'false'
GO
ALTER DATABASE Development SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE Development


-- Remove the registration of the local Publisher at the Distributor.
USE distribution
EXEC sp_dropdistpublisher N'AlexY10';

-- Delete the distribution database.

EXEC sp_dropdistributiondb N'Distribution';

-- Remove the local server as a Distributor.
EXEC sp_dropdistributor;
GO


use master 
go 
alter database Development set offline; 
drop database Development;

