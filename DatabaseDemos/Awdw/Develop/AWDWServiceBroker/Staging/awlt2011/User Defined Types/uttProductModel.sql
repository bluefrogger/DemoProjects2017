CREATE TYPE [awlt2011].[uttProductModel] AS TABLE(
	[ProductModelID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [dbo].[Name] NOT NULL,
	[CatalogDescription] [xml] NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL DEFAULT (newid()),
	[ModifiedDate] [datetime] NOT NULL DEFAULT (getdate())
)