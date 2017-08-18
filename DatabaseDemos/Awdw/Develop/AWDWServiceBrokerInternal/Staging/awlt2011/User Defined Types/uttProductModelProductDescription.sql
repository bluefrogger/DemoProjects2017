CREATE TYPE [awlt2011].[uttProductModelProductDescription] AS TABLE(
	[ProductModelID] [int] NOT NULL,
	[ProductDescriptionID] [int] NOT NULL,
	[Culture] [nchar](6) NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL DEFAULT (newid()),
	[ModifiedDate] [datetime] NOT NULL DEFAULT (getdate())
)