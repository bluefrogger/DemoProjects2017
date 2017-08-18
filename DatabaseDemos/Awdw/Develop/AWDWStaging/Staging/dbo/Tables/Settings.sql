CREATE TABLE dbo.Settings
(
	Id           INT IDENTITY(1,1)
   ,Name         NVARCHAR(512)
   ,Detail       NVARCHAR(512)
   ,Value        NVARCHAR(512)
   ,ValueDefault NVARCHAR(512)
   ,SettingStatus  INT
);
