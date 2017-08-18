CREATE TYPE [awlt2011].[uttAddress] AS TABLE(
	[AddressID] [int] NOT NULL,
	[AddressLine1] [nvarchar](60) NOT NULL,
	[AddressLine2] [nvarchar](60) NULL,
	[City] [nvarchar](30) NOT NULL,
	[StateProvince] [dbo].[Name] NOT NULL,
	[CountryRegion] [dbo].[Name] NOT NULL,
	[PostalCode] [nvarchar](15) NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL DEFAULT (newid()),
	[ModifiedDate] [datetime] NOT NULL DEFAULT (getdate())
)