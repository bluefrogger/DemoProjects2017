CREATE TYPE [awlt2011].[uttProductDescription] AS TABLE(
	[ProductDescriptionID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](400) NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL DEFAULT (newid()),
	[ModifiedDate] [datetime] NOT NULL DEFAULT (getdate())
)