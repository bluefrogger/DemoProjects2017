USE [Staging]
GO
/****** Object:  UserDefinedDataType [dbo].[AccountNumber]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [dbo].[AccountNumber] FROM [nvarchar](30) NULL
GO
/****** Object:  UserDefinedDataType [dbo].[Flag]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [dbo].[Flag] FROM [bit] NULL
GO
/****** Object:  UserDefinedDataType [dbo].[Name]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [dbo].[Name] FROM [nvarchar](100) NULL
GO
/****** Object:  UserDefinedDataType [dbo].[NameStyle]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [dbo].[NameStyle] FROM [bit] NULL
GO
/****** Object:  UserDefinedDataType [dbo].[OrderNumber]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [dbo].[OrderNumber] FROM [nvarchar](50) NULL
GO
/****** Object:  UserDefinedDataType [dbo].[Phone]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [dbo].[Phone] FROM [nvarchar](50) NULL
GO
/****** Object:  UserDefinedTableType [awlt2011].[Address]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[Address] AS TABLE(
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
/****** Object:  UserDefinedTableType [awlt2011].[Customer]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[Customer] AS TABLE(
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
/****** Object:  UserDefinedTableType [awlt2011].[CustomerAddress]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[CustomerAddress] AS TABLE(
	[CustomerID] [int] NULL,
	[AddressID] [int] NULL,
	[AddressType] [dbo].[Name] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[Product]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[Product] AS TABLE(
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
/****** Object:  UserDefinedTableType [awlt2011].[ProductCategory]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[ProductCategory] AS TABLE(
	[ProductCategoryID] [int] NULL,
	[ParentProductCategoryID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[ProductDescription]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[ProductDescription] AS TABLE(
	[ProductDescriptionID] [int] NULL,
	[Description] [nvarchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[ProductModel]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[ProductModel] AS TABLE(
	[ProductModelID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[CatalogDescription] [xml] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[ProductModelProductDescription]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[ProductModelProductDescription] AS TABLE(
	[ProductModelID] [int] NULL,
	[ProductDescriptionID] [int] NULL,
	[Culture] [nchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
)
GO
/****** Object:  UserDefinedTableType [awlt2011].[SalesOrderDetail]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[SalesOrderDetail] AS TABLE(
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
/****** Object:  UserDefinedTableType [awlt2011].[SalesOrderHeader]    Script Date: 5/8/2016 6:09:03 PM ******/
CREATE TYPE [awlt2011].[SalesOrderHeader] AS TABLE(
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
/****** Object:  Table [awlt2011].[Address]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [awlt2011].[Address](
	[AddressID] [int] NULL,
	[AddressLine1] [nvarchar](4000) NULL,
	[AddressLine2] [nvarchar](4000) NULL,
	[City] [nvarchar](4000) NULL,
	[StateProvince] [dbo].[Name] NULL,
	[CountryRegion] [dbo].[Name] NULL,
	[PostalCode] [nvarchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles]

GO
/****** Object:  Table [awlt2011].[Customer]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [awlt2011].[Customer](
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
) ON [DataFiles]

GO
SET ANSI_PADDING ON
GO
/****** Object:  Table [awlt2011].[CustomerAddress]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [awlt2011].[CustomerAddress](
	[CustomerID] [int] NULL,
	[AddressID] [int] NULL,
	[AddressType] [dbo].[Name] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles]

GO
/****** Object:  Table [awlt2011].[Product]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [awlt2011].[Product](
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
) ON [DataFiles]

GO
SET ANSI_PADDING ON
GO
/****** Object:  Table [awlt2011].[ProductCategory]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [awlt2011].[ProductCategory](
	[ProductCategoryID] [int] NULL,
	[ParentProductCategoryID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles]

GO
/****** Object:  Table [awlt2011].[ProductDescription]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [awlt2011].[ProductDescription](
	[ProductDescriptionID] [int] NULL,
	[Description] [nvarchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles]

GO
/****** Object:  Table [awlt2011].[ProductModel]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [awlt2011].[ProductModel](
	[ProductModelID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[CatalogDescription] [xml] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles] TEXTIMAGE_ON [DataFiles]

GO
/****** Object:  Table [awlt2011].[ProductModelProductDescription]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [awlt2011].[ProductModelProductDescription](
	[ProductModelID] [int] NULL,
	[ProductDescriptionID] [int] NULL,
	[Culture] [nchar](4000) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles]

GO
/****** Object:  Table [awlt2011].[SalesOrderDetail]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [awlt2011].[SalesOrderDetail](
	[SalesOrderID] [int] NULL,
	[SalesOrderDetailID] [int] NULL,
	[OrderQty] [smallint] NULL,
	[ProductID] [int] NULL,
	[UnitPrice] [money] NULL,
	[UnitPriceDiscount] [money] NULL,
	[LineTotal] [numeric](38, 38) NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles]

GO
/****** Object:  Table [awlt2011].[SalesOrderHeader]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [awlt2011].[SalesOrderHeader](
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
) ON [DataFiles]

GO
SET ANSI_PADDING ON
GO
/****** Object:  Table [dbo].[LogActivity]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogActivity](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Handle] [uniqueidentifier] NULL,
	[ProcedureName] [sysname] NULL,
	[LoginName] [nvarchar](512) NULL,
	[UserName] [nvarchar](512) NULL,
	[LogDate] [date] NULL,
	[LogTime] [time](7) NULL,
	[LogStatus] [int] NULL
) ON [DataFiles]

GO
/****** Object:  Table [dbo].[LogError]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

GO
/****** Object:  Table [dbo].[Settings]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Settings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](512) NULL,
	[Detail] [nvarchar](512) NULL,
	[Value] [nvarchar](512) NULL,
	[ValueDefault] [nvarchar](512) NULL,
	[SettingStatus] [int] NULL
) ON [DataFiles]

GO
/****** Object:  Table [dbo].[Statuses]    Script Date: 5/8/2016 6:09:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Statuses](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](512) NULL,
	[Detail] [nvarchar](512) NULL
) ON [DataFiles]

GO
