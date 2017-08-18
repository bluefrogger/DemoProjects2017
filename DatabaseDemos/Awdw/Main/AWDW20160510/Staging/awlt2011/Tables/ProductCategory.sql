CREATE TABLE [awlt2011].[ProductCategory](
	[ProductCategoryID] [int] NULL,
	[ParentProductCategoryID] [int] NULL,
	[Name] [dbo].[Name] NULL,
	[rowguid] [uniqueidentifier] NULL,
	[ModifiedDate] [datetime] NULL
) ON [DataFiles]