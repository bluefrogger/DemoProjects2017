--http://sqlperformance.com/2012/07/t-sql-queries/running-totals

USE [master];
GO
IF DB_ID('RunningTotals') IS NOT NULL
BEGIN
	ALTER DATABASE RunningTotals SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE RunningTotals;
END
GO
CREATE DATABASE RunningTotals;
GO
USE RunningTotals;
GO
SET NOCOUNT ON;
GO

/*Create table*/
CREATE TABLE dbo.SpeedingTickets
(
	[Date]      DATE NOT NULL,
	TicketCount INT
);
GO
 
/*Fill with 10,000 rows*/
ALTER TABLE dbo.SpeedingTickets ADD CONSTRAINT pk PRIMARY KEY CLUSTERED ([Date]);
GO
 
;WITH x(d,h) AS
(
	SELECT TOP (250)
		ROW_NUMBER() OVER (ORDER BY [object_id]),
		CONVERT(INT, RIGHT([object_id], 2))
	FROM sys.all_objects
	ORDER BY [object_id]
)
INSERT dbo.SpeedingTickets([Date], TicketCount)
SELECT TOP (10000)
	d = DATEADD(DAY, x2.d + ((x.d-1)*250), '19831231'),
	x2.h
FROM x CROSS JOIN x AS x2
ORDER BY d;
GO
 
SELECT [Date], TicketCount
	FROM dbo.SpeedingTickets
	ORDER BY [Date];
GO

/*Quirky Update*/
DECLARE @st TABLE
(
	[Date] DATE PRIMARY KEY,
	TicketCount INT,
	RunningTotal INT
);
 
DECLARE @RunningTotal INT = 0;
 
INSERT @st([Date], TicketCount, RunningTotal)
	SELECT [Date], TicketCount, RunningTotal = 0
	FROM dbo.SpeedingTickets
	ORDER BY [Date];


UPDATE @st
	SET @RunningTotal = RunningTotal = @RunningTotal + TicketCount
	FROM @st;
 
SELECT [Date], TicketCount, RunningTotal
	FROM @st
	ORDER BY [Date];

/*Cursor*/

DECLARE @st TABLE(
	TicketDate DATE PRIMARY KEY
    , TicketCount INT
	, RunningTotal int
)

DECLARE @TicketDate DATE, @TicketCount INT, @RunningTotal INT

DECLARE c CURSOR FOR
SELECT Date, TicketCount FROM dbo.SpeedingTickets AS st

OPEN c

FETCH NEXT FROM c INTO @TicketDate, @TicketCount

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @RunningTotal = @RunningTotal + @TicketCount

	INSERT @st(Date, TicketCount, RunningTotal)
	SELECT @TicketDate, @TicketCount, @RunningTotal

	FETCH NEXT FROM c INTO @Date, @TicketCount;
END

CLOSE c;
DEALLOCATE c;

SELECT * FROM @st ORDER BY date

SELECT	date, st.TicketCount, SUM(st.TicketCount) OVER (ORDER BY date)
FROM dbo.SpeedingTickets AS st

SELECT	date, st.TicketCount, SUM(st.TicketCount) OVER (ORDER BY date ROWS UNBOUNDED PRECEDING TO CURRENT ROW)
FROM dbo.SpeedingTickets AS st

SELECT	date, st.TicketCount, SUM(st.TicketCount) OVER (ORDER BY date RANGE UNBOUNDED PRECEDING TO CURRENT ROW)
FROM dbo.SpeedingTickets AS st

