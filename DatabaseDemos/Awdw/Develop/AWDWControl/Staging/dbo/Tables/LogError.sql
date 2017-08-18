CREATE TABLE [dbo].[LogError](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Handle] [uniqueidentifier] NULL,
	[ErrorNumber] [int] NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorState] [int] NULL,
	[ErrorProcedure] [nvarchar](128) NULL,
	[ErrorLine] [int] NULL,
	[ErrorMessage] [nvarchar](4000) NULL
) ON [DataFiles]
