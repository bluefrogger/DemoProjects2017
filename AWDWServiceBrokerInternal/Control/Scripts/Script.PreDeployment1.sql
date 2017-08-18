/*
 Pre-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be executed before the build script.	
 Use SQLCMD syntax to include a file in the pre-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the pre-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

IF NOT EXISTS(
	SELECT * FROM sys.service_broker_endpoints
	WHERE name = 'AlexY10Endpoint'
)
CREATE ENDPOINT AlexY10Endpoint
STATE = STARTED
AS TCP 
(
    LISTENER_PORT = 9998
)
FOR SERVICE_BROKER
(
    AUTHENTICATION = WINDOWS,
    ENCRYPTION = DISABLED
)
GO

