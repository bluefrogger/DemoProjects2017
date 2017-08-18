-- batch insert into existing table
set nocount on
while 1 = 1
begin
	delete top(10)
	from etl.NameColor
	where Name between 'aa' and 'll'
end

declare @BatchSize int = 10000

while 1 = 1
begin

	insert etl.NameColor --with(tablock) in 2008 for minimal logging
	(
		Name
		,Color
	)
	select top(@BatchSize)
		ss.id
		,ss.Name
		,ss.Color
	from etl.NameColor as ss
	--where id between 1 and 100000 --also multi threaded batch like this
	where not exists (
		select *
		from etl.NameColorArchive as aa --need ts in archive since duplicate id
		where aa.id = ss.id --need non clustered index on both table(id)
	)
	if @@rowcount < @BatchSize break

end
go
--------------------------------------------------------------------------------
--insert random data
create schema test authorization dbo;
go
create table test.BillingInfo (
	id int identity
	,BillingDate smalldatetime
	,BillingAmt decimal(18,4)
	,BillingDesc varchar(500)
)
declare @i int = 0
	,@BillingDate int;

while @i < 100000
begin
	
	set @i = @i + 1;
	set @BillingDate = cast(rand() * 10000 as int) % 3650 --number of days less than 10 years

	insert test.BillingInfo (BillingDate, BillingAmt)
	values (dateadd(dd
				, @BillingDate
				,cast('1999-01-01' as smalldatetime))
			,rand() * 5000
	);
end

select dateadd(dd, 3 , getdate())
select cast(rand() * 10000 as int) % 3650
go

create table test.SalesInfo (
	SaleID int
	,ProductID int
	,Quantity int
	,SaleAmount decimal(18,4)
	,SaleDate smalldatetime
)

insert test.SalesInfo (SaleID, ProductID, Quantity, SaleAmount, SaleDate)
select top 100
	row_number() over(order by(select null)) as SaleID
	,newid() as ProductID
	,abs(checksum(newid())) as Quantity
--	,SQL_VARIANT_PROPERTY(abs(checksum(newid())), 'basetype') as datatype
	,cast(cast(newid() as varbinary) as int) as SaleAmount
	,dateadd(dd, abs(checksum(newid()) % 3650), '2000-01-01') as SaleDate
from sys.columns as aa
cross join sys.columns as bb

--------------------------------------------------------------------------------

-- try catch throw

declare @error_msg varchar(4000)
	,@error_severity smallint
	,@error_state smallint;

begin try
	select 1/0;
end try
begin catch
	throw;
	select @error_msg = error_message()
		,@error_severity = ERROR_SEVERITY()
		,@error_state = error_state();
	raiserror(@error_msg, @error_severity, @error_state);
end catch
--------------------------------------------------------------------------------
USE AdventureWorks2012;
GO

IF OBJECT_ID('UpdateSales', 'P') IS NOT NULL
DROP PROCEDURE UpdateSales;
GO

CREATE PROCEDURE UpdateSales
  @SalesPersonID INT,
  @SalesAmt MONEY = 0
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;
      UPDATE LastYearSales
      SET SalesLastYear = SalesLastYear + @SalesAmt
      WHERE SalesPersonID = @SalesPersonID;
    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
  END CATCH
END;
GO

/*
ERROR_NUMBER(): The number assigned to the error.
ERROR_LINE(): The line number inside the routine that caused the error.
ERROR_MESSAGE(): The error message text, which includes the values supplied for any substitutable parameters
	, such as times or object names.
ERROR_SEVERITY(): The error’s severity.
ERROR_STATE(): The error’s state number.
ERROR_PROCEDURE(): The name of the stored procedure or trigger that generated the error.
*/
--------------------------------------------------------------------------------
ALTER PROCEDURE UpdateSales
  @SalesPersonID INT,
  @SalesAmt MONEY = 0
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;
      UPDATE LastYearSales
      SET SalesLastYear = SalesLastYear + @SalesAmt
      WHERE SalesPersonID = @SalesPersonID;
    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

    THROW;
  END CATCH
END;
IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
GO
--------------------------------------------------------------------------------
restore database contoso
from disk = 'C:\TEMP\FlatFile\ContosoRetailDW.bak'
with move 'ContosoRetailDW2.0' to 'C:\Program Files\Microsoft SQL Server\Data\ContosoRetailDW.mdf'
,move 'ContosoRetailDW2.0_log' to 'C:\Program Files\Microsoft SQL Server\Data\ContosoRetailDW.ldf';
go

restore filelistonly
from disk = 'C:\TEMP\FlatFile\ContosoRetailDW.bak'
--------------------------------------------------------------------------------
USE [aw12]
GO
select SalesOrderID
from [Sales].[SalesOrderHeader]
where Status = 5;

CREATE NONCLUSTERED INDEX nci_SalesOrderHeader_Status
ON [Sales].[SalesOrderHeader] ([Status])
--drop index nci_SalesOrderHeader_Status on [Sales].[SalesOrderHeader] 


[Sales].[SalesOrderDetail]

