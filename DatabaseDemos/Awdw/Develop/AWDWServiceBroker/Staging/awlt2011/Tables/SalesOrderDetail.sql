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