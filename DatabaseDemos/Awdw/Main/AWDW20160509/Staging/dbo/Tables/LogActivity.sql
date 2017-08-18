CREATE TABLE [dbo].[LogActivity](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Handle] [uniqueidentifier] NULL,
	[ProcedureName] [sysname] NULL,
	[LoginName] [nvarchar](512) NULL,
	[UserName] [nvarchar](512) NULL,
	[LogDate] [date] NULL,
	[LogTime] [time](7) NULL,
	[LogStatus] [int] NULL
) ON [DataFiles]
 