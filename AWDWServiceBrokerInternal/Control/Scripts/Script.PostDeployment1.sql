/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
ALTER QUEUE dbo.ExtractInitQueue
WITH ACTIVATION(
	STATUS = ON
	, PROCEDURE_NAME = dbo.uspExtractInitActivation
	, MAX_QUEUE_READERS = 1
	, EXECUTE AS SELF	
)

GRANT SEND ON SERVICE::[ExtractInitService] TO [Public];
GO

DECLARE @guid NVARCHAR(36) = (SELECT CAST(service_broker_guid AS NVARCHAR(36)) FROM sys.databases WHERE name = 'Control');
DECLARE @sql NVARCHAR(500) = 
	'CREATE ROUTE TestRemoteRoute
		WITH
			SERVICE_NAME = ''ExtractInitService''
			, ADDRESS = ''tcp://AlexY10.bcnt.local:9998''
			, BROKER_INSTANCE = ''' + @guid + ''';'
EXEC(@sql);
GO
