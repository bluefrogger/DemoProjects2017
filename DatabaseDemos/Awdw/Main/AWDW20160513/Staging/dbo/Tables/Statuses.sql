CREATE TABLE [dbo].[Statuses](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](512) NULL,
	[Detail] [nvarchar](512) NULL
) ON [DataFiles]
