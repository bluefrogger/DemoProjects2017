/*
	http://searchsqlserver.techtarget.com/tip/Different-ways-to-audit-SQL-Server-security
*/
USE [master]
GO

DROP TABLE [dbo].[SecurityLog]
GO

CREATE TABLE [dbo].[SecurityLog](
      [EventType]         [nvarchar](128) NULL, 
      [EventTime]         [datetime] NULL,
      [EventLog]          [xml] NULL

) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

--Now create a DDL trigger (ddl_trig_capture_security_events) to capture and store all connections and security-related events:

USE [master]
GO

IF EXISTS (SELECT * FROM sys.server_triggers
          WHERE name = 'ddl_trig_capture_security_events')
DROP TRIGGER ddl_trig_capture_security_events
ON ALL SERVER;
GO

 
CREATE TRIGGER ddl_trig_capture_security_events ON ALL SERVER
FOR  LOGON, DDL_SERVER_SECURITY_EVENTS,        
       DDL_DATABASE_SECURITY_EVENTS
AS    
      INSERT INTO [master]..[SecurityLog] (EventType, EventTime, EventLog)      
     SELECT EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]','nvarchar(128)')              
		,EVENTDATA().value('(/EVENT_INSTANCE/PostTime)[1]','datetime')             
		,EVENTDATA()

GO

--Once the trigger has been created, you can test to see if it is working:

USE [master]
GO

CREATE LOGIN [TestDDL] WITH PASSWORD=N'TestDDL'
GO

USE [AdventureWorks2012]
GO

CREATE USER [TestDDL] FOR LOGIN [TestDDL]
GO

ALTER ROLE [db_datareader] ADD MEMBER [TestDDL]
GO

GRANT EXECUTE ON [dbo].[uspGetBillOfMaterials] TO [TestDDL]
GO

--Click on xml to view the full event log:
--The following figure shows the output when you choose to view the log table:
