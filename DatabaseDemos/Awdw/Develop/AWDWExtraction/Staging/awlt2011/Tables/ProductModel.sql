CREATE TABLE [awlt2011].[ProductModel](
	[ProductModelID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[CatalogDescription] [xml] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles] TEXTIMAGE_ON [DataFiles]