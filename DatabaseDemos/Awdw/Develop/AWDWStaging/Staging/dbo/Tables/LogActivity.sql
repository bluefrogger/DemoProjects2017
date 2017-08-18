CREATE TABLE dbo.LogActivity
(
	Id            INT IDENTITY(1,1)
   ,Handle        UNIQUEIDENTIFIER
   ,ProcedureName SYSNAME
   ,LoginName     NVARCHAR(512)
   ,UserName      NVARCHAR(512)
   ,LogDate       DATE
   ,LogTime       TIME
   ,LogStatus     INT
);
 