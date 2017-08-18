CREATE TABLE [dbo].[Settings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](512) NULL,
	[Detail] [nvarchar](512) NULL,
	[Value] [nvarchar](512) NULL,
	[ValueDefault] [nvarchar](512) NULL,
	[SettingStatus] [int] NULL
) ON [DataFiles]
