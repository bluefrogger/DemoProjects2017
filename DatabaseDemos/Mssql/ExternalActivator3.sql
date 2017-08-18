/*
http://devkimchi.com/831/service-broker-external-activator-for-sql-server-step-by-step-2/
*/

USE [master]
GO

IF NOT EXISTS (SELECT * FROM sys.syslogins WHERE name = 'NT SERVICESSBExternalActivator')
BEGIN
    CREATE LOGIN [NT SERVICE\SSBExternalActivator] FROM WINDOWS
END
GO

USE [TrackingDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT SERVICESSBExternalActivator')
BEGIN
    CREATE USER [NT SERVICE\SSBExternalActivator] FOR LOGIN [NT SERVICE\SSBExternalActivator]
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT SERVICE\SSBExternalActivator]
GO

USE [SourceDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT SERVICESSBExternalActivator')
BEGIN
    CREATE USER [NT SERVICESSBExternalActivator] FOR LOGIN [NT SERVICESSBExternalActivator]
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT SERVICESSBExternalActivator]
GO

-- Allows CONNECT to [SourceDB].
GRANT CONNECT
    TO [NT SERVICE\SSBExternalActivator]
GO

-- Allows RECEIVE from the queue for the external actvator app.
GRANT RECEIVE
    ON CheckRegisterTargetQueue
    TO [NT SERVICE\SSBExternalActivator]
GO

-- Allows VIEW DEFINITION right on the service for the external activator app.
GRANT VIEW DEFINITION
    ON SERVICE::CheckRegisterTargetService
    TO [NT SERVICE\SSBExternalActivator]
GO

-- Allows REFRENCES right on the queue schema for the external activator app.
GRANT REFERENCES
    ON SCHEMA::dbo
    TO [NT SERVICE\SSBExternalActivator]
GO

USE [master]
GO

IF NOT EXISTS (SELECT * FROM sys.syslogins WHERE name = 'NT AUTHORITYANONYMOUS LOGON')
BEGIN
    CREATE LOGIN [NT AUTHORITY\ANONYMOUS LOGON] FROM WINDOWS
END

USE [TrackingDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT AUTHORITYANONYMOUS LOGON')
BEGIN
    CREATE USER [NT AUTHORITY\ANONYMOUS LOGON] FOR LOGIN [NT AUTHORITY\ANONYMOUS LOGON] 
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITYANONYMOUS LOGON]
GO

USE [SourceDB]
GO

IF NOT EXISTS (SELECT * FROM sys.sysusers WHERE name = 'NT AUTHORITYANONYMOUS LOGON')
BEGIN
    CREATE USER [NT AUTHORITYANONYMOUS LOGON] FOR LOGIN [NT AUTHORITYANONYMOUS LOGON]
END
GO

ALTER ROLE [db_owner] ADD MEMBER [NT AUTHORITY\ANONYMOUS LOGON] 
GO

-- Allows CONNECT to [SourceDB].
GRANT CONNECT
    TO [NT AUTHORITY\ANONYMOUS LOGON] 
GO

-- Allows RECEIVE from the queue for the external actvator app.
GRANT RECEIVE
    ON CheckRegisterTargetQueue
    TO [NT AUTHORITY\ANONYMOUS LOGON] 
GO

-- Allows VIEW DEFINITION right on the service for the external activator app.
GRANT VIEW DEFINITION
    ON SERVICE::CheckRegisterTargetService
    TO [NT AUTHORITY\ANONYMOUS LOGON] 
GO

-- Allows REFRENCES right on the queue schema for the external activator app.
GRANT REFERENCES
    ON SCHEMA::dbo
    TO [NT AUTHORITY\ANONYMOUS LOGON]
GO
