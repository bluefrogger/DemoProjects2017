USE [Staging]
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttAddress]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttAddress] AS TABLE(
	[AddressID] [int] NULL,
	[AddressLine1] [nvarchar](4000) NULL,
	[AddressLine2] [nvarchar](4000) NULL,
	[City] [nvarchar](4000) NULL,
	[StateProvince] [dbo].[Name] NULL,
	[CountryRegion] [dbo].[Name] NULL,
	[PostalCode] [nvarchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttCustomer]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttCustomer] AS TABLE(
	[CustomerID] [int] NULL,
	[NameStyle] [dbo].[NameStyle] NULL,
	[Title] [nvarchar](4000) NULL,
	[FirstName] [dbo].[Name] NULL,
	[MiddleName] [dbo].[Name] NULL,
	[LastName] [dbo].[Name] NULL,
	[Suffix] [nvarchar](4000) NULL,
	[CompanyName] [nvarchar](4000) NULL,
	[SalesPerson] [nvarchar](4000) NULL,
	[EmailAddress] [nvarchar](4000) NULL,
	[Phone] [dbo].[Phone] NULL,
	[PasswordHash] [varchar](8000) NULL,
	[PasswordSalt] [varchar](8000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttCustomerAddress]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttCustomerAddress] AS TABLE(
	[CustomerID] [int] NULL,
	[AddressID] [int] NULL,
	[AddressType] [dbo].[Name] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttProduct]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttProduct] AS TABLE(
	[ProductID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[ProductNumber] [nvarchar](4000) NULL,
	[Color] [nvarchar](4000) NULL,
	[StandardCost] [money] NULL,
	[ListPrice] [money] NULL,
	[Size] [nvarchar](4000) NULL,
	[Weight] [decimal](38, 38) NULL,
	[ProductCategoryID] [int] NULL,
	[ProductModelID] [int] NULL,
	[SellStartDate] [datetime] NULL,
	[SellEndDate] [datetime] NULL,
	[DiscontinuedDate] [datetime] NULL,
	[ThumbNailPhoto] [varbinary](1) NULL,
	[ThumbnailPhotoFileName] [nvarchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttProductCategory]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttProductCategory] AS TABLE(
	[ProductCategoryID] [int] NULL,
	[ParentProductCategoryID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttProductDescription]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttProductDescription] AS TABLE(
	[ProductDescriptionID] [int] NULL,
	[Description] [nvarchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttProductModel]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttProductModel] AS TABLE(
	[ProductModelID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[CatalogDescription] [xml] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttProductModelProductDescription]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttProductModelProductDescription] AS TABLE(
	[ProductModelID] [int] NULL,
	[ProductDescriptionID] [int] NULL,
	[Culture] [nchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttSalesOrderDetail]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttSalesOrderDetail] AS TABLE(
	[SalesOrderID] [int] NULL,
	[SalesOrderDetailID] [int] NULL,
	[OrderQty] [smallint] NULL,
	[ProductID] [int] NULL,
	[UnitPrice] [money] NULL,
	[UnitPriceDiscount] [money] NULL,
	[LineTotal] [numeric](38, 38) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[uttSalesOrderHeader]    Script Date: 5/8/2016 6:44:23 PM ******/
CREATE TYPE [awlt2011].[uttSalesOrderHeader] AS TABLE(
	[SalesOrderID] [int] NULL,
	[RevisionNumber] [tinyint] NULL,
	[OrderDate] [datetime] NULL,
	[DueDate] [datetime] NULL,
	[ShipDate] [datetime] NULL,
	[Status] [tinyint] NULL,
	[OnlineOrderFlag] [dbo].[Flag] NULL,
	[SalesOrderNumber] [nvarchar](4000) NULL,
	[PurchaseOrderNumber] [dbo].[OrderNumber] NULL,
	[AccountNumber] [dbo].[AccountNumber] NULL,
	[CustomerID] [int] NULL,
	[ShipToAddressID] [int] NULL,
	[BillToAddressID] [int] NULL,
	[ShipMethod] [nvarchar](4000) NULL,
	[CreditCardApprovalCode] [varchar](8000) NULL,
	[SubTotal] [money] NULL,
	[TaxAmt] [money] NULL,
	[Freight] [money] NULL,
	[TotalDue] [money] NULL,
	[Comment] [nvarchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
