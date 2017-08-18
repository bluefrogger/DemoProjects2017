CREATE TYPE [awlt2011].[uttCustomerAddress] AS TABLE(
	[CustomerID] [int] NOT NULL,
	[AddressID] [int] NOT NULL,
	[AddressType] [dbo].[Name] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL DEFAULT (newid()),
	[ModifiedDate] [datetime] NOT NULL DEFAULT (getdate())
)