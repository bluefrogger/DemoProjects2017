-- http://stevestedman.com/2012/10/tsql-rounding-datetime-to-nearest-seconds/

declare @dtVariable as datetime;
set @dtVariable = getdate();
SELECT GETDATE()

-- if you are testing this before noon, uncomment the
--     following line to simulate an after noon time.
--set @dtVariable = dateadd(hour, 12, @dtVariable)
 
-- Rounding to the second
select @dtVariable as Original,
       DATEADD(ms, 500 - DATEPART(ms, @dtVariable + '00:00:00.500'),
               @dtVariable) as RoundedToSecond;

-- Truncated to the minute
select @dtVariable as Original,
       DATEADD(minute, DATEDIFF(minute, 0, @dtVariable), 0) as TruncatedToMinute;

-- Rounded to minute
SELECT  @dtVariable AS Original,
        DATEADD(MINUTE,
                DATEDIFF(MINUTE, 0,
                         DATEADD(SECOND,
                                 30 - DATEPART(SECOND, @dtVariable + '00:00:30.000'),
                                 @dtVariable)), 0) AS RoundedToMinute;

-- Truncated to the hour
select @dtVariable as Original,
       DATEADD(hour, DATEDIFF(hour, 0, @dtVariable), 0) as TruncatedToHour;

-- Rounded to hour
select @dtVariable as Original,
       DATEADD(hour, DATEDIFF(hour, 0,
             DATEADD(minute, 30 - DATEPART(minute, @dtVariable + '00:30:00.000'),
             @dtVariable)), 0)  as RoundedToHour;

-- Truncated to the day
select @dtVariable as Original,
       DATEADD(Day, DATEDIFF(Day, 0, @dtVariable), 0) as TruncatedToDay;

-- Rounded to day
select @dtVariable as Original,
       DATEADD(day, DATEDIFF(day, 0,
             DATEADD(hour, 12 - DATEPART(hour, @dtVariable + '12:00:00.000'),
             @dtVariable)), 0)  as RoundedToDay;
