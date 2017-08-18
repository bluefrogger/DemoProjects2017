/*
	http://searchsqlserver.techtarget.com/tip/Different-ways-to-audit-SQL-Server-security
	SQL Server audit uses extended events to help perform an audit.
*/

CREATE SERVER AUDIT [Audit-SecurityEvents]
TO FILE
(      FILEPATH = N'D:\Demo_SQLAudit'       
      ,MAXSIZE = 200 MB       
      ,MAX_ROLLOVER_FILES = 2147483647       
       ,RESERVE_DISK_SPACE = OFF )
WITH
(      QUEUE_DELAY = 1000       
          ,ON_FAILURE = CONTINUE )
GO

CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpecification]
FOR SERVER AUDIT [Audit-SecurityEvents]
ADD (LOGIN_CHANGE_PASSWORD_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (SERVER_PRINCIPAL_CHANGE_GROUP)
GO

