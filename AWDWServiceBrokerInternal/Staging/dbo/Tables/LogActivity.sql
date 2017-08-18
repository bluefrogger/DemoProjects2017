CREATE TABLE dbo.LogActivity
(
	Id            INT IDENTITY(1, 1) NOT NULL
  , Handle        UNIQUEIDENTIFIER NULL constraint df_LogActivity_Handle default (cast(cast(0 as binary(16)) as uniqueidentifier))
  , ProcedureName SYSNAME NULL 
  , Parameter     NVARCHAR(4000)
  , ReturnValue   NVARCHAR(4000)
  , LoginName     NVARCHAR(512) NULL constraint df_LogActivitiy_LoginName default (suser_name())
  , UserName      NVARCHAR(512) NULL constraint df_LogActivitiy_UserName default (user_name())
  , LogDate       [DATE] NULL constraint df_LogActivity_LogDate default (convert(date, getdate()))
  , LogTime       [TIME](0) NULL constraint df_LogActivity_LogTime default (convert(time(0), getdate()))
  , LogStatus     INT NULL,
)
ON [DataFiles];