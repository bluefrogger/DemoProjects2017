/*
	http://searchsqlserver.techtarget.com/tip/Different-ways-to-audit-SQL-Server-security
	http://www.sqlservercentral.com/articles/Event+Notifications/68831/
	https://technet.microsoft.com/en-us/library/ms189855(v=sql.105).aspx
	https://www.sqlskills.com/blogs/jonathan/event-notifications-vs-extended-events/
	http://colleenmorrow.com/2013/04/15/event-notifications-101-intro-to-event-notifications/
	SQL Server 2005 and offer the ability to collect a very specific subset of 
	SQL Trace, DDL and security-related events through a Service Broker
*/
USE [msdb]
GO

--Creating queue

CREATE QUEUE [SecurityEventsQueue]
GO

--Creating service for the queue

CREATE SERVICE [//AdventureWorks.com/SecurityEventsService]
AUTHORIZATION [dbo]
ON QUEUE [dbo].[SecurityEventsQueue]
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

--Creating route for the service

CREATE ROUTE SecurityEventsRoute
WITH SERVICE_NAME = '//AdventureWorks.com/SecurityEventsService',
ADDRESS = 'LOCAL';
GO

--Creating Event Notification to capture connection and secrity-related events

USE [msdb]
GO
CREATE EVENT NOTIFICATION NotifySecurityEvents
ON SERVER
FOR AUDIT_LOGIN,       
       AUDIT_LOGOUT,       
      AUDIT_LOGIN_FAILED,       
      DDL_SERVER_SECURITY_EVENTS,       
      DDL_DATABASE_SECURITY_EVENTS
TO SERVICE '//AdventureWorks.com/SecurityEventsService' ,    
           '9D584F73-1796-4494-ADC2-04BDD729FBCE';
GO

--Creating the service program that will process the event messages that is

--generated via Event Notification objects

IF EXISTS (SELECT * FROM [sys].[objects] WHERE [name] = 'sProcessSecurityEvents')
DROP PROCEDURE [dbo].[sProcessSecurityEvents]
GO

CREATE PROC [dbo].[sProcessSecurityEvents]
AS BEGIN

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON

BEGIN TRY

DECLARE  @message_body [xml]             
             ,@EventTime [datetime]             
            ,@EventType [varchar](128)             
           ,@message_type_name [nvarchar](256)             
           ,@dialog [uniqueidentifier]

-- Endless loop

WHILE (1 = 1)
BEGIN
BEGIN TRANSACTION ;

-- Receive the next available message

WAITFOR (RECEIVE TOP(1)                    
                  @message_type_name = [message_type_name],                    
                 @message_body = [message_body],                    
                 @dialog = [conversation_handle]
FROM [dbo].[SecurityEventsQueue]), TIMEOUT 2000

-- Rollback and exit if no messages were found

IF (@@ROWCOUNT = 0)
BEGIN       
        ROLLBACK TRANSACTION;       
        BREAK;
END;

-- End conversation of end dialog message

IF (@message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog')

BEGIN       
       PRINT 'End Dialog received for dialog # ' + CAST(@dialog as [nvarchar](40));       
       END CONVERSATION @dialog;
       END;

ELSE
BEGIN       
       SET @EventTime = CAST(CAST(@message_body.query('/EVENT_INSTANCE/PostTime/text()') AS [nvarchar](max)) AS [datetime])       
       SET @EventType = CAST(@message_body.query('/EVENT_INSTANCE/EventType/text()') AS [nvarchar](128))       
       INSERT INTO [master]..[SecurityLog] ([EventType], [EventTime], [EventLog])       
      VALUES (@EventType, @EventTime, @message_body)
END

COMMIT TRANSACTION

END --End of loop

END TRY

BEGIN CATCH

SELECT ERROR_NUMBER()             
            ,ERROR_SEVERITY()             
            ,ERROR_STATE()             
            ,ERROR_PROCEDURE()             
            ,ERROR_LINE()             
            ,ERROR_MESSAGE()

END CATCH

END
GO

--Once service program is created successfully, execute the following script to

--activate our service broker queue and reference this Service Program stored procedure:

ALTER QUEUE [dbo].[SecurityEventsQueue]        
        WITH STATUS = ON       
        ,ACTIVATION (PROCEDURE_NAME = [sProcessSecurityEvents]       
        ,STATUS = ON       
        ,MAX_QUEUE_READERS = 1       
         ,EXECUTE AS OWNER)
GO

--Now test the Event Notification setup and then examine the output of the SecurityLog table.
