--Things to add:
--MaxAppointments
--RecurrenceEndDate
--variable start time(need to grab all the special slot entries for a day


DECLARE @start DATETIME = '2016-03-29 08:45:23'
   ,@end DATETIME = '2016-03-30 14:44:23'
   ,@physicianID INT = 1088156
   ,@practiceID INT = 1004057
   ,@practiceGroupID INT = 1001004
   ,@subjectiveRFVID INT = 1071116;

DECLARE @DateDay NVARCHAR(10)
   ,@DayStringStart INT
   ,@DayStringEnd INT
   ,@Recurrence NVARCHAR(MAX)
   ,@Difference INT
   ,@Parsethis NVARCHAR(MAX)
   ,@Block INT = 20
   ,@EndDate DATETIME
   ,@AppointmentID INT
   ,@SpecialSlotID INT
   ,@ReadOnlySlot BIT;
DECLARE @StartTime DATETIME
   ,@EndTime DATETIME;

--Create temp tables
CREATE TABLE #SpecialSlots (SpecialSlotID INT
                           ,StartDate DATETIME
                           ,EndDate DATETIME
                           ,RecurrencePattern NVARCHAR(MAX));

CREATE TABLE #TimeSlots (StartTime DATETIME
                        ,EndTime DATETIME);

CREATE TABLE #CurrentAppts (ID INT IDENTITY(1, 1)
                           ,StartTime DATETIME
                           ,EndTime DATETIME);

--Get current appointments for day being searched
INSERT  INTO #CurrentAppts (StartTime, EndTime)
        SELECT  SA.StartDate, SA.EndDate
        FROM    dbo.sa_Appointments AS SA
                INNER JOIN dbo.sa_AppointmentResources AS SAR ON SAR.AppointmentID = SA.AppointmentID
                INNER JOIN dbo.sa_Resources AS SR ON SR.ResourceID = SAR.AppointmentResourceID
        WHERE   SR.PhysicianID = @physicianID
                AND SA.PracticeID = @practiceID
                AND CONVERT(DATE, SA.StartDate) = CONVERT(DATE, @start)
        ORDER BY SA.StartDate, SA.EndDate;

--Cursor through special slots
DECLARE specCur CURSOR LOCAL FAST_FORWARD
FOR
SELECT  SSS.SpecialSlotID, SSST.ReadOnlySlot, SSS.RecurrencePattern
FROM    dbo.sa_SpecialSlots AS SSS
        INNER JOIN dbo.sa_SpecialSlotTypes AS SSST ON SSST.SpecialSlotTypeID = SSS.SpecialSlotTypeID
WHERE   SSS.StartDate <= @start
        AND SSS.PracticeID = @practiceID
        AND SSS.PhysicianID = @physicianID;
OPEN specCur;
FETCH NEXT FROM specCur INTO @SpecialSlotID, @ReadOnlySlot, @Recurrence;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Recurrence LIKE 'FREQ=WEEKLY%'
    BEGIN

        SET @DayStringStart = CHARINDEX('BYDAY=', @Recurrence) + 6;
        SET @DayStringEnd = CHARINDEX(';', @Recurrence, @DayStringStart);

        IF @DayStringEnd = 0
            SET @DayStringEnd = LEN(@Recurrence) + 1;

        SET @Difference = @DayStringEnd - @DayStringStart;
        SET @Parsethis = (SUBSTRING(@Recurrence, @DayStringStart, @Difference));
    END;

    IF @DateDay IN (SELECT  (CASE WHEN item = 'mo' THEN 'Monday'
                                  WHEN item = 'tu' THEN 'Tuesday'
                                  WHEN item = 'we' THEN 'Wednesday'
                                  WHEN item = 'th' THEN 'Thursday'
                                  WHEN item = 'fr' THEN 'Friday'
                             END)
                    FROM    SplitStrings_CTE(@Parsethis, ','))
        OR @Recurrence LIKE 'FREQ=DAILY%'
        AND @ReadOnlySlot = 1
        INSERT  INTO #CurrentAppts (StartTime, EndTime)
                SELECT  SSS.StartDate, SSS.EndDate
                FROM    dbo.sa_SpecialSlots AS SSS
                WHERE   SSS.SpecialSlotID = @SpecialSlotID;

    FETCH NEXT FROM specCur INTO @SpecialSlotID, @ReadOnlySlot, @Recurrence;
END;
CLOSE specCur;
DEALLOCATE specCur;



SET @StartTime = CONVERT(DATETIME, CONVERT(DATE, @start))
    + (SELECT   CONVERT(TIME, SSS.StartDate)
       FROM     dbo.sa_SpecialSlots AS SSS
       WHERE    SSS.SpecialSlotID = 1081);

IF @StartTime < @start
    SET @StartTime = CONVERT(DATETIME, CONVERT(DATE, @start))
        + (SELECT   dbo.RoundTime(CONVERT(TIME, @start), 10));

--SELECT @StartTime

SET @EndTime = CONVERT(DATETIME, CONVERT(DATE, @end))
    + (SELECT   CONVERT(TIME, SSS.EndDate)
       FROM     dbo.sa_SpecialSlots AS SSS
       WHERE    SSS.SpecialSlotID = 1081);

 
--Get day of week from StartDate
SET @DateDay = (SELECT  DATENAME(dw, GETDATE()));
SET @Recurrence = (SELECT   RecurrencePattern
                   FROM     dbo.sa_SpecialSlots
                   WHERE    SpecialSlotID = 1081);


IF @Recurrence LIKE 'FREQ=WEEKLY%'
BEGIN

    SET @DayStringStart = CHARINDEX('BYDAY=', @Recurrence) + 6;
    SET @DayStringEnd = CHARINDEX(';', @Recurrence, @DayStringStart);

    IF @DayStringEnd = 0
        SET @DayStringEnd = LEN(@Recurrence) + 1;

    SET @Difference = @DayStringEnd - @DayStringStart;
    SET @Parsethis = (SUBSTRING(@Recurrence, @DayStringStart, @Difference));
END;

IF @DateDay IN (SELECT  (CASE WHEN item = 'mo' THEN 'Monday'
                              WHEN item = 'tu' THEN 'Tuesday'
                              WHEN item = 'we' THEN 'Wednesday'
                              WHEN item = 'th' THEN 'Thursday'
                              WHEN item = 'fr' THEN 'Friday'
                         END)
                FROM    SplitStrings_CTE(@Parsethis, ','))
    OR @Recurrence LIKE 'FREQ=DAILY%'
BEGIN
	--Add blocks to list while they end before or at the endtime of the pattern
    WHILE DATEADD(MINUTE, @Block, @StartTime) <= @EndTime
    BEGIN
			--Cursor through current appointments
        DECLARE cur1 CURSOR LOCAL FAST_FORWARD
        FOR
        SELECT  CA.ID
        FROM    #CurrentAppts AS CA;
        OPEN cur1;
        FETCH NEXT FROM cur1 INTO @AppointmentID;

	 
        WHILE @@FETCH_STATUS = 0
        BEGIN
			 --If @Starttime falls inside an appointment, set @starttime to the endtime of that appointment
            IF @StartTime >= (SELECT    StartTime
                              FROM      #CurrentAppts
                              WHERE     ID = @AppointmentID)
                AND @StartTime < (SELECT    EndTime
                                  FROM      #CurrentAppts
                                  WHERE     ID = @AppointmentID)
                SET @StartTime = CONVERT(DATETIME, CONVERT(DATE, @start))
                    + (SELECT   dbo.RoundTime(CONVERT(TIME, (SELECT EndTime FROM #CurrentAppts WHERE ID = @AppointmentID)), 10));

            FETCH NEXT FROM cur1 INTO @AppointmentID;
        END;
        CLOSE cur1;
        DEALLOCATE cur1;

        INSERT  INTO #TimeSlots (StartTime, EndTime)
        VALUES  (@StartTime, -- StartTime - datetime
                 DATEADD(MINUTE, @Block, @StartTime)  -- EndTime - datetime
                 );
        SET @StartTime = DATEADD(MINUTE, @Block, @StartTime);
			
        IF DATEADD(MINUTE, @Block, @StartTime) > @EndTime
            BREAK;
        ELSE
            CONTINUE;
    END;

END;
SELECT  TS.StartTime, TS.EndTime
FROM    #TimeSlots AS TS;

--SELECT * FROM #CurrentAppts AS CA

DROP TABLE #TimeSlots;
DROP TABLE #CurrentAppts;

