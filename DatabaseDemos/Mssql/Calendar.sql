/*
	https://www.mssqltips.com/sqlservertip/4054/creating-a-date-dimension-or-calendar-table-in-sql-server/
	http://www.sqlservercentral.com/blogs/dwainsql/2014/03/30/calendar-tables-in-t-sql/
*/

DECLARE @StartDate DATE = '20000101', @NumberOfYears INT = 30;

-- prevent set or regional settings from interfering with 
-- interpretation of dates / literals

SET DATEFIRST 7;
SET DATEFORMAT mdy;
SET LANGUAGE US_ENGLISH;

DECLARE @CutoffDate DATE = DATEADD(YEAR, @NumberOfYears, @StartDate);

-- this is just a holding table for intermediate calculations:

CREATE TABLE #dim
(
  [date]       DATE PRIMARY KEY, 
  [day]        AS DATEPART(DAY,      [date]),
  [month]      AS DATEPART(MONTH,    [date]),
  FirstOfMonth AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
  [MonthName]  AS DATENAME(MONTH,    [date]),
  [week]       AS DATEPART(WEEK,     [date]),
  [ISOweek]    AS DATEPART(ISO_WEEK, [date]),
  [DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
  [quarter]    AS DATEPART(QUARTER,  [date]),
  [year]       AS DATEPART(YEAR,     [date]),
  FirstOfYear  AS CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
  Style112     AS CONVERT(CHAR(8),   [date], 112),
  Style101     AS CONVERT(CHAR(10),  [date], 101)
);

-- use the catalog views to generate as many rows as we need

INSERT #dim([date]) 
SELECT d
FROM
(
  SELECT d = DATEADD(DAY, rn - 1, @StartDate)
  FROM 
  (
    SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
      rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
    FROM sys.all_objects AS s1
    CROSS JOIN sys.all_objects AS s2
    -- on my system this would support > 5 million days
    ORDER BY s1.[object_id]
  ) AS x
) AS y;

select * from #dim

INSERT dbo.DateDimension WITH (TABLOCKX)
SELECT
  DateKey       = CONVERT(INT, Style112),
  [Date]        = [date],
  [Day]         = CONVERT(TINYINT, [day]),
  DaySuffix     = CONVERT(CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE 
                  CASE RIGHT([day], 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
	              WHEN '3' THEN 'rd' ELSE 'th' END END),
  [Weekday]     = CONVERT(TINYINT, [DayOfWeek]),
  [WeekDayName] = CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date])),
  [IsWeekend]   = CONVERT(BIT, CASE WHEN [DayOfWeek] IN (1,7) THEN 1 ELSE 0 END),
  [IsHoliday]   = CONVERT(BIT, 0),
  HolidayText   = CONVERT(VARCHAR(64), NULL),
  [DOWInMonth]  = CONVERT(TINYINT, ROW_NUMBER() OVER 
                  (PARTITION BY FirstOfMonth, [DayOfWeek] ORDER BY [date])),
  [DayOfYear]   = CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date])),
  WeekOfMonth   = CONVERT(TINYINT, DENSE_RANK() OVER 
                  (PARTITION BY [year], [month] ORDER BY [week])),
  WeekOfYear    = CONVERT(TINYINT, [week]),
  ISOWeekOfYear = CONVERT(TINYINT, ISOWeek),
  [Month]       = CONVERT(TINYINT, [month]),
  [MonthName]   = CONVERT(VARCHAR(10), [MonthName]),
  [Quarter]     = CONVERT(TINYINT, [quarter]),
  QuarterName   = CONVERT(VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' 
                  WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END), 
  [Year]        = [year],
  MMYYYY        = CONVERT(CHAR(6), LEFT(Style101, 2)    + LEFT(Style112, 4)),
  MonthYear     = CONVERT(CHAR(7), LEFT([MonthName], 3) + LEFT(Style112, 4)),
  FirstDayOfMonth     = FirstOfMonth,
  LastDayOfMonth      = MAX([date]) OVER (PARTITION BY [year], [month]),
  FirstDayOfQuarter   = MIN([date]) OVER (PARTITION BY [year], [quarter]),
  LastDayOfQuarter    = MAX([date]) OVER (PARTITION BY [year], [quarter]),
  FirstDayOfYear      = FirstOfYear,
  LastDayOfYear       = MAX([date]) OVER (PARTITION BY [year]),
  FirstDayOfNextMonth = DATEADD(MONTH, 1, FirstOfMonth),
  FirstDayOfNextYear  = DATEADD(YEAR,  1, FirstOfYear)
FROM #dim
OPTION (MAXDOP 1);

;WITH x AS 
(
  SELECT DateKey, [Date], IsHoliday, HolidayText, FirstDayOfYear,
    DOWInMonth, [MonthName], [WeekDayName], [Day],
    LastDOWInMonth = ROW_NUMBER() OVER 
    (
      PARTITION BY FirstDayOfMonth, [Weekday] 
      ORDER BY [Date] DESC
    )
  FROM dbo.DateDimension
)
UPDATE x SET IsHoliday = 1, HolidayText = CASE
  WHEN ([Date] = FirstDayOfYear) 
    THEN 'New Year''s Day'
  WHEN ([DOWInMonth] = 3 AND [MonthName] = 'January' AND [WeekDayName] = 'Monday')
    THEN 'Martin Luther King Day'    -- (3rd Monday in January)
  WHEN ([DOWInMonth] = 3 AND [MonthName] = 'February' AND [WeekDayName] = 'Monday')
    THEN 'President''s Day'          -- (3rd Monday in February)
  WHEN ([LastDOWInMonth] = 1 AND [MonthName] = 'May' AND [WeekDayName] = 'Monday')
    THEN 'Memorial Day'              -- (last Monday in May)
  WHEN ([MonthName] = 'July' AND [Day] = 4)
    THEN 'Independence Day'          -- (July 4th)
  WHEN ([DOWInMonth] = 1 AND [MonthName] = 'September' AND [WeekDayName] = 'Monday')
    THEN 'Labour Day'                -- (first Monday in September)
  WHEN ([DOWInMonth] = 2 AND [MonthName] = 'October' AND [WeekDayName] = 'Monday')
    THEN 'Columbus Day'              -- Columbus Day (second Monday in October)
  WHEN ([MonthName] = 'November' AND [Day] = 11)
    THEN 'Veterans'' Day'            -- Veterans' Day (November 11th)
  WHEN ([DOWInMonth] = 4 AND [MonthName] = 'November' AND [WeekDayName] = 'Thursday')
    THEN 'Thanksgiving Day'          -- Thanksgiving Day (fourth Thursday in November)
  WHEN ([MonthName] = 'December' AND [Day] = 25)
    THEN 'Christmas Day'
  END
WHERE 
  ([Date] = FirstDayOfYear)
  OR ([DOWInMonth] = 3     AND [MonthName] = 'January'   AND [WeekDayName] = 'Monday')
  OR ([DOWInMonth] = 3     AND [MonthName] = 'February'  AND [WeekDayName] = 'Monday')
  OR ([LastDOWInMonth] = 1 AND [MonthName] = 'May'       AND [WeekDayName] = 'Monday')
  OR ([MonthName] = 'July' AND [Day] = 4)
  OR ([DOWInMonth] = 1     AND [MonthName] = 'September' AND [WeekDayName] = 'Monday')
  OR ([DOWInMonth] = 2     AND [MonthName] = 'October'   AND [WeekDayName] = 'Monday')
  OR ([MonthName] = 'November' AND [Day] = 11)
  OR ([DOWInMonth] = 4     AND [MonthName] = 'November' AND [WeekDayName] = 'Thursday')
  OR ([MonthName] = 'December' AND [Day] = 25);

go
UPDATE d SET IsHoliday = 1, HolidayText = 'Black Friday'
FROM dbo.DateDimension AS d
INNER JOIN
(
  SELECT DateKey, [Year], [DayOfYear]
  FROM dbo.DateDimension 
  WHERE HolidayText = 'Thanksgiving Day'
) AS src 
ON d.[Year] = src.[Year] 
AND d.[DayOfYear] = src.[DayOfYear] + 1;
go
CREATE FUNCTION [dbo].[GenerateCalendar] 
        (
        @FromDate   DATETIME 
        ,@NoDays    INT			
        )

go
CREATE FUNCTION dbo.GetEasterHolidays(@year INT) 
RETURNS TABLE
WITH SCHEMABINDING
AS 
RETURN 
(
  WITH x AS 
  (
    SELECT [Date] = CONVERT(DATE, RTRIM(@year) + '0' + RTRIM([Month]) 
        + RIGHT('0' + RTRIM([Day]),2))
      FROM (SELECT [Month], [Day] = DaysToSunday + 28 - (31 * ([Month] / 4))
      FROM (SELECT [Month] = 3 + (DaysToSunday + 40) / 44, DaysToSunday
      FROM (SELECT DaysToSunday = paschal - ((@year + @year / 4 + paschal - 13) % 7)
      FROM (SELECT paschal = epact - (epact / 28)
      FROM (SELECT epact = (24 + 19 * (@year % 19)) % 30) 
        AS epact) AS paschal) AS dts) AS m) AS d
  )
  SELECT [Date], HolidayName = 'Easter Sunday' FROM x
    UNION ALL SELECT DATEADD(DAY,-2,[Date]), 'Good Friday'   FROM x
    UNION ALL SELECT DATEADD(DAY, 1,[Date]), 'Easter Monday' FROM x
);

go
;WITH x AS 
(
  SELECT d.[Date], d.IsHoliday, d.HolidayText, h.HolidayName
    FROM dbo.DateDimension AS d
    CROSS APPLY dbo.GetEasterHolidays(d.[Year]) AS h
    WHERE d.[Date] = h.[Date]
)
UPDATE x SET IsHoliday = 1, HolidayText = HolidayName;

go
-- Generates a calendar table with sequential day numbering (@FromDate = SeqNo 1).
-- See RETURNS table (comments) for meaning of each column.
-- Notes:       1) Max for NoDays is 65536, which runs in just over 2 seconds.
--
-- Example calls to generate the calendar:
-- 1) Forward for 365 days starting today:
--             DECLARE @Date DATETIME
--             SELECT @Date = GETDATE()
--             SELECT * 
--             FROM dbo.GenerateCalendar(@Date, 365) 
--             ORDER BY SeqNo;
-- 2) Backwards for 365 days back starting today:
--             DECLARE @Date DATETIME
--             SELECT @Date = GETDATE()
--             SELECT * 
--             FROM dbo.GenerateCalendar(@Date, -365) 
--             ORDER BY SeqNo;
-- 3) For only the FromDate:
--             DECLARE @Date DATETIME
--             SELECT @Date = GETDATE()
--             SELECT * 
--             FROM dbo.GenerateCalendar(@Date, 1);
-- 4) Including only the last week days of each month:
--             Note: Seq no in this case are as if all dates were generated
--             DECLARE @Date DATETIME
--             SELECT @Date = GETDATE()
--             SELECT * 
--             FROM dbo.GenerateCalendar(@Date, 365) 
--             WHERE Last = 1 ORDER BY SeqNo;
RETURNS TABLE WITH SCHEMABINDING AS
 RETURN
--===== High speed code provided courtesy of SQL MVP Jeff Moden (idea by Dwain Camps)
--===== Generate sequence numbers from 1 to 65536 (credit to SQL MVP Itzik Ben-Gen)
   WITH  E1(N) AS (SELECT 1 UNION ALL SELECT 1), --2 rows
         E2(N) AS (SELECT 1 FROM E1 a, E1 b),    --4 rows
         E4(N) AS (SELECT 1 FROM E2 a, E2 b),    --16 rows
         E8(N) AS (SELECT 1 FROM E4 a, E4 b),    --256 rows
        E16(N) AS (SELECT 1 FROM E8 a, E8 b),    --65536 rows
   cteTally(N) AS (
SELECT TOP (ABS(@NoDays)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E16)
        -- [SeqNo]=Sequential day number (@FromDate always=1) forward or backwards
 SELECT [SeqNo]     = t.N,
        -- [Date]=Date (with 00:00:00.000 for the time component)                              
        [Date]      = dt.DT,  
        -- [Year]=Four digit year                                  
        [Year]      = dp.YY,
        -- [YrNN]=Two digit year                                    
        [YrNN]      = dp.YY % 100,
        -- [YYYYMM]=Integer YYYYMM (year * 100 + month)                              
        [YYYYMM]    = dp.YY * 100 + dp.MM,
        -- [BuddhaYr]=Year in Buddhist calendar                      
        [BuddhaYr]  = dp.YY + 543, 
        -- [Month]=Month (as an INT)                             
        [Month]     = dp.MM, 
        -- [Day]=Day (as an INT)                                   
        [Day]       = dp.DD,
        -- [WkDNo]=Week day number (based on @@DATEFIRST)                                    
        [WkDNo]     = DATEPART(dw,dt.DT),
        -- Next 3 columns dependent on language setting so may not work for non-English  
        -- [WkDName]=Full name of the week day, e.g., Monday, Tuesday, etc.                     
        [WkDName]   = CONVERT(NCHAR(9),dp.DW), 
        -- [WkDName2]=Two characters for the week day, e.g., Mo, Tu, etc.                 
        [WkDName2]  = CONVERT(NCHAR(2),dp.DW),  
        -- [WkDName3]=Three characters for the week day, e.g., Mon, Tue, etc.                
        [WkDName3]  = CONVERT(NCHAR(3),dp.DW),  
        -- [JulDay]=Julian day (day number of the year)                
        [JulDay]    = dp.DY,
        -- [JulWk]=Week number of the year                                    
        [JulWk]     = dp.DY/7+1,
        -- [WkNo]=Week number                                
        [WkNo]      = dp.DD/7+1,
        -- [Qtr]=Quarter number (of the year)                                
        [Qtr]       = DATEPART(qq,dt.Dt),                       
        -- [Last]=Number the weeks for the month in reverse      
        [Last]      = (DATEPART(dd,dp.LDtOfMo)-dp.DD)/7+1,
        -- [LdOfMo]=Last day of the month                  
        [LdOfMo]    = DATEPART(dd,dp.LDtOfMo),
        -- [LDtOfMo]=Last day of the month as a DATETIME
        [LDtOfMo]   = dp.LDtOfMo                                
   FROM cteTally t
  CROSS APPLY 
  ( --=== Create the date
        SELECT DT = DATEADD(dd,(t.N-1)*SIGN(@NoDays),@FromDate)
  ) dt
  CROSS APPLY 
  ( --=== Create the other parts from the date above using a "cCA"
    -- (Cascading CROSS APPLY (cCA), courtesy of Chris Morris)
        SELECT YY        = DATEPART(yy,dt.DT), 
                MM        = DATEPART(mm,dt.DT), 
                DD        = DATEPART(dd,dt.DT), 
                DW        = DATENAME(dw,dt.DT),
                Dy        = DATEPART(dy,dt.DT),
                LDtOfMo   = DATEADD(mm,DATEDIFF(mm,-1,dt.DT),-1)

  ) dp;

select * from [dbo].[GenerateCalendar] ('2000-01-01', 1000)
select * from dbo.Calendar 

SELECT [Date], [Year], [YrNN], [YYYYMM], [BuddhaYr], [Month], [Day]
    ,[WkDNo], [WkDName], [WkDName2], [WkDName3], [JulDay], [JulWk]
    ,[WkNo], [Qtr], [Last], [LdOfMo], [LDtOfMo]
INTO dbo.Calendar 
FROM dbo.GenerateCalendar('2010-01-01', 65536);

-- Change column types to be NOT NULL so we can index them
ALTER TABLE dbo.Calendar ALTER COLUMN [Date] DATETIME NOT NULL;
ALTER TABLE dbo.Calendar ALTER COLUMN [Year] INT NOT NULL;
ALTER TABLE dbo.Calendar ALTER COLUMN [Month] INT NOT NULL;
ALTER TABLE dbo.Calendar ALTER COLUMN [YYYYMM] INT NOT NULL;
ALTER TABLE dbo.Calendar ALTER COLUMN [Day] INT NOT NULL;
GO
-- Build some representative INDEXes
ALTER TABLE dbo.Calendar ADD CONSTRAINT Cal_pk PRIMARY KEY([Date]);
ALTER TABLE dbo.Calendar ADD CONSTRAINT Cal_ix1 UNIQUE NONCLUSTERED([Year], [Month], [Day]);
ALTER TABLE dbo.Calendar ADD CONSTRAINT Cal_ix2 UNIQUE NONCLUSTERED([YYYYMM], [Day]);

SELECT TOP 10 [Date], [YYYYMM], [WkDName2], [WkNo], [Last]
FROM dbo.Calendar;	

SELECT [Date]
FROM dbo.Calendar
WHERE [Date] BETWEEN '2014-01-01' AND '2014-12-31' AND
    [WkDName2] = 'MO' AND [WkNo] = 1;

/*
select datediff(mm, -1, getdate())
	,dateadd(mm, datediff(mm, -1, getdate()), -1)
	,datediff(mm, '2000-01-01', getdate())
*/
use staging
declare @StartDate date = '2000-01-01'
declare @EndDate date = '2003-12-31'

select
	nb
	, dt.Dt
	, convert(char(8), dt.Dt, 112) as Dt112
	, convert(char(10), dt.Dt, 101) as Dt101
	, dp.YY
	, dp.MM
	, dp.FDtofMM
	, dp.LDtofMM
	, dp.QQ
	, min(dt.Dt) over (partition by dp.QQ) as FDtofQQ
	, max(dt.Dt) over (partition by dp.QQ) as LDtofQQ
	, dp.DD
	, dp.Dw
	, DwName
	, convert(nchar(3), dp.DwName) as DwShort
	, convert(nchar(2), dp.DwName) as DwAbbr
	, dp.Dy as DDofYY
	, dp.Dw as DDofWk
	, dp.Dy / 7 + 1 as WkofYY
	, dp.DD / 7 + 1 as WkOfMM
	, (datepart(dd, dp.LDtofMM) - dp.DD) / 7 + 1 as WkNoReverse
	, datepart(dd, dp.LDtofMM) as LDDofMM
into dbo.Calendar
from dbo.Tally
cross apply(
	select dateadd(dd, nb, @StartDate) as Dt
) as dt
cross apply(
	select datepart(yy, dt.Dt) as YY
		, datepart(mm, dt.Dt) as MM
		, datepart(dd, dt.Dt) as DD
		, datepart(qq, dt.Dt) as QQ
		, datepart(dw, dt.Dt) as Dw
		, datename(dw, dt.Dt) as DwName
		, datepart(dy, dt.Dt) as Dy
		, convert(date, dateadd(mm, datediff(mm, 0, dt.DT), 0)) as FDtofMM
		, convert(date, dateadd(mm, datediff(mm, -1, dt.DT), -1)) as LDtofMM
) as dp
where nb <= datediff(dd, @StartDate, @Enddate)

