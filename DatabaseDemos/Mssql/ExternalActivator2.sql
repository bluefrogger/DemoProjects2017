/*
https://blogs.msdn.microsoft.com/sql_service_broker/2009/05/18/get-started-with-using-external-activator/
*/
-- switch to the database where you want to define the notification service
USE ODS
GO

-- create a queue to host the notification service
CREATE QUEUE CheckRegisterTargetQueue
GO

-- create event notification service
CREATE SERVICE CheckRegisterTargetService
ON QUEUE CheckRegisterTargetQueue
(
	[http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
)
GO

/*
Next, let’s create an event notification object so whenever messages have arrived at the user queue 
you are interested in (my_user_queue), notifications will be posted to the notification service we just created above:
*/
CREATE EVENT NOTIFICATION CheckRegisterTargetEvent
ON QUEUE CheckRegisterTargetQueue
FOR QUEUE_ACTIVATION
TO SERVICE 'CheckRegisterTargetService' , 'current database';
GO

/*
 The windows login-account external activator service is running under needs to have the set of permissions 
 that are listed in Security Implications section of 
 C:\Program Files\Service Broker\External Activator\bin\<language_id>\ssbea.doc 
 in order to connect to the notification service and database to read notification messages from the notification service queue
*/

--switch to master database
USE master
GO

--create a sql-login for the same named service account from windows
CREATE LOGIN [NT AUTHORITY\NETWORK SERVICE] FROM WINDOWS
GO

--switch to the notification database
USE ODS
GO

--allow CONNECT to the notification database
GRANT CONNECT TO [NT AUTHORITY\NETWORK SERVICE]
GO

--allow RECEIVE from the notification service queue
GRANT RECEIVE ON CheckRegisterNotificationQueue TO [NT AUTHORITY\NETWORK SERVICE]
GO

--allow VIEW DEFINITION right on the notification service
GRANT VIEW DEFINITION ON SERVICE::CheckRegisterNotificationService TO [NT AUTHORITY\NETWORK SERVICE]
GO

--allow REFRENCES right on the notification queue schema
GRANT REFERENCES ON SCHEMA::dbo TO [NT AUTHORITY\NETWORK SERVICE]
GO

ALTER ROLE [db_owner] drop MEMBER [NT AUTHORITY\NETWORK SERVICE]

/*
http://stackoverflow.com/questions/10299870/event-nofication-on-queue-activation-stops-working-after-queue-is-disabled-and-e
http://rusanu.com/2008/08/03/understanding-queue-monitors/
http://blog.maskalik.com/sql-server-service-broker/troubleshooting-external-activation/
*/

USE ssisdb

CREATE USER [NT AUTHORITY\NETWORK SERVICE] FROM LOGIN [NT AUTHORITY\NETWORK SERVICE]
ALTER ROLE ssis_admin ADD MEMBER [NT AUTHORITY\NETWORK SERVICE]

