CREATE TABLE dbo.LogError
(
	Id             INT IDENTITY(1,1)
   ,Handle         UNIQUEIDENTIFIER
   ,ErrorNumber    INT
   ,ErrorSeverity  INT
   ,ErrorState     INT
   ,ErrorProcedure NVARCHAR(128)
   ,ErrorLine      INT
   ,ErrorMessage   NVARCHAR(4000)
);
