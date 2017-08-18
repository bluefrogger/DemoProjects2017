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
--alter assembly AWDWClr with permission_set = unsafe;
:r .\DomainData\DataStatuses.sql
:r .\DomainData\DataTally.sql
:r .\DomainData\DataDimDate.sql
:r .\DomainData\DataLogCalendar.sql

ALTER QUEUE dbo.ExtractTargetQueue
WITH ACTIVATION(
	STATUS = ON
    , PROCEDURE_NAME = dbo.uspExtractTargetActivation
	, MAX_QUEUE_READERS = 1
	, EXECUTE AS SELF
);
GO
