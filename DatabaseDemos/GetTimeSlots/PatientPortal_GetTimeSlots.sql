/*
Author: Alex Yoo
Created: 2016-07-19
Detail: Sql version of sh_sp_GetTimeSlots.cs Clr on shSql1.coredev.solutahealth.com
Change Log:

Notes:
AppointmentResourceID int = 6500000, 
StartDate datetime, (test schedule for Monday/Tuesday 8am-5pm)
EndDate datetime, 
RFVID int = 1071002 (20 minute timeslots)

CREATE ASSEMBLY GetTimeSlots
FROM 'C:\Users\Alex.yoo\Documents\Visual Studio 2015\Projects\WorkProjects\GetTimeSlots\bin\Debug\GetTimeSlots.dll'
WITH PERMISSION_SET = unsafe;  
GO

CREATE FUNCTION dbo.udfTimeZoneInfoGetUtcOffset(@TimeZoneName NVARCHAR(128))
RETURNS INT
AS EXTERNAL NAME GetTimeSlots.UserDefinedFunctions.TimeZoneInfoGetUtcOffset
GO
*/

--SELECT *
--FROM dbo.sa_SpecialSlots 
--INNER JOIN dbo.sa_SpecialSlotTypes 
--	ON dbo.sa_SpecialSlots.SpecialSlotTypeID = dbo.sa_SpecialSlotTypes.SpecialSlotTypeID
--WHERE dbo.sa_SpecialSlots.PracticeID = 1004049 
--			AND dbo.sa_SpecialSlots.PhysicianID = 1088051

--SELECT *
--FROM dbo.sa_AppointmentResources
--INNER JOIN dbo.sa_Appointments
--	ON dbo.sa_AppointmentResources.AppointmentID = dbo.sa_Appointments.AppointmentID
--INNER JOIN dbo.sa_Resources
--	ON dbo.sa_AppointmentResources.AppointmentResourceID = dbo.sa_Resources.ResourceID
--WHERE dbo.sa_Resources.PhysicianID = 1088051
--AND dbo.sa_Resources.PracticeID = 1004049

--CREATE PROC dbo.PatientPortal_GetTimeSlots
--(
--	@start DATETIME
--	, @end DATETIME
--	, @physicianID INT
--	, @practiceID INT
--  , @practiceGroupID INT
--  , @subjectiveRFVID INT
--)
--AS BEGIN
	--BEGIN TRY
		SET NOCOUNT ON;

		DECLARE @start DATETIME = '2013-09-30 00:00:00.000';
		DECLARE @end DATETIME = '2013-09-30 23:59:59.999';
		DECLARE @physicianID INT = 1088051;
		DECLARE @practiceID INT = 1004049;
		DECLARE @practiceGroupID INT;
		DECLARE @subjectiveRFVID INT = 1071002;

		DECLARE @length INT = 0;
		DECLARE @maxAppts INT = 1;
		DECLARE @tzOffset INT = 300; --Eastern

		DECLARE @TimeZoneName NVARCHAR(128);
		DECLARE @UseNewScheduler BIT;

		DECLARE @queryStart DATETIME = GETDATE();
		DECLARE @Debug INT = 1;

		/* #region Get TimeZone & NewScheduler properties for Practice */
		SELECT @TimeZoneName = dbo.sh_TimeZones.TimeZoneName
			, @UseNewScheduler = dbo.sh_PracticePreferences.UseNewScheduler
		FROM dbo.sh_PracticePreferences
		INNER JOIN dbo.sh_TimeZones
			ON dbo.sh_PracticePreferences.TimeZoneID = dbo.sh_TimeZones.TimeZoneID
		WHERE (dbo.sh_PracticePreferences.PracticeID = @practiceID);

		IF (@TimeZoneName IS NULL OR @UseNewScheduler IS NULL)
			RAISERROR ('Error raised in TRY block.', 16, 1);  

		--IF (@Debug = 1)
		--	SELECT @TimeZoneName AS TimeZoneName, @UseNewScheduler AS UseNewScheduler;

		IF (@TimeZoneName IS NOT NULL)
			SET @tzOffset = dbo.GetUtcOffset(@TimeZoneName);

		/* #region Get Length of SubjectiveRFV */
		SELECT @length = dbo.sh_SubjectiveRFVs.AppointmentTimeMinutes
			, @maxAppts = dbo.sh_SubjectiveRFVs.MaxAppointments
		FROM dbo.sh_SubjectiveRFVs
		WHERE dbo.sh_SubjectiveRFVs.SubjectiveRFVID = @SubjectiveRFVID
		AND (dbo.sh_SubjectiveRFVs.PracticeID = @PracticeID 
			OR dbo.sh_SubjectiveRFVs.PracticeGroupID = @PracticeGroupID
			);

		--IF (@Debug = 1)
		--	SELECT @length AS ApptLength, @maxAppts AS MaxAppts, @tzOffset AS tzOffset;

		/* #region Collect Appointments */
		DECLARE @Appointments AS TABLE(
			StartDate DATETIME NOT NULL
			, EndDate DATETIME NOT NULL
		);
		INSERT @Appointments(StartDate, EndDate)
		SELECT dbo.sa_Appointments.StartDate
			, dbo.sa_Appointments.EndDate
		FROM dbo.sa_AppointmentResources
		INNER JOIN dbo.sa_Appointments
			ON dbo.sa_AppointmentResources.AppointmentID = dbo.sa_Appointments.AppointmentID
		INNER JOIN dbo.sa_Resources
			ON dbo.sa_AppointmentResources.AppointmentResourceID = dbo.sa_Resources.ResourceID
		WHERE (dbo.sa_Resources.PhysicianID = @PhysicianID)
		AND (dbo.sa_Resources.PracticeID = @PracticeID)
		AND (dbo.sa_Appointments.StartDate >= CONVERT(datetime, @start))
		AND (dbo.sa_Appointments.StartDate <= CONVERT(datetime, @end))
		ORDER BY dbo.sa_Appointments.StartDate;

		IF (@Debug = 1)
			SELECT * FROM @Appointments AS a;

		/* #region Collect SpecialSlots */
		DECLARE @SpecialSlot AS TABLE(
			Name nvarchar(128) NOT null
			, IsReadOnly BIT NULL
			, StartDate DATETIME NULL
			, EndDate DATETIME NULL
			, RecurrencePattern NVARCHAR(256) NULL
		);
		INSERT @SpecialSlot(Name, IsReadOnly, StartDate, EndDate, RecurrencePattern)
		SELECT dbo.sa_SpecialSlotTypes.Name
			, dbo.sa_SpecialSlotTypes.ReadOnlySlot
			, dbo.sa_SpecialSlots.StartDate
			, dbo.sa_SpecialSlots.EndDate
			, dbo.sa_SpecialSlots.RecurrencePattern
		FROM dbo.sa_SpecialSlots 
		INNER JOIN dbo.sa_SpecialSlotTypes 
			ON dbo.sa_SpecialSlots.SpecialSlotTypeID = dbo.sa_SpecialSlotTypes.SpecialSlotTypeID
		WHERE dbo.sa_SpecialSlots.PracticeID = @PracticeID 
			AND dbo.sa_SpecialSlots.PhysicianID = @PhysicianID
		ORDER BY dbo.sa_SpecialSlots.StartDate;

		IF (@Debug = 1)
		BEGIN
			INSERT @SpecialSlot(Name, IsReadOnly, StartDate, EndDate, RecurrencePattern)
			VALUES ('Available',	0, '2016-07-14 08:00:00.000', '2016-08-14 11:00:00.000', 'FREQ=WEEKLY;BYDAY=SU,MO,TU,WE,TH,SA')
				,('Lunch',	1, '2016-07-14 12:00:00.000', '2016-08-14 13:00:00.000', 'FREQ=WEEKLY;BYDAY=SU,MO,TU,WE,TH,SA');
			--SELECT * FROM @SpecialSlot AS ss;
		END;
		/*	#region Generate TimeSlots
			If using new scheduler, determine initial starting point based on first Available SpecialSlot in db result.
			Result must be ordered by StartDate above.
		*/
		IF (@UseNewScheduler = 1)
		BEGIN
			SELECT TOP (1) @start = StartDate
			FROM @SpecialSlot
			WHERE Name = 'Available'
			ORDER BY StartDate;
		END;

		/* Only allow timeslots for the future. */
		DECLARE @LocalOffset INT = ABS(DATEDIFF(minute, GETUTCDATE(), GETDATE()));
		DECLARE @Delta INT = (@tzOffset - @LocalOffset) * (-1);
		DECLARE @CurrentDateTime DATETIME = DATEADD(minute, @Delta, GETDATE()) -- GETDATE();

		IF (@CurrentDateTime > @start)
			SET @start = @CurrentDateTime;

		-- Round to nearest 10 minutes
		SET @start = DATEADD(MINUTE, (60 - DATEPART(MINUTE, @start)) % 10, @start);
		-- Truncate seconds
		SET @start = DATEADD(minute, DATEDIFF(minute, '1970-01-01', @start), '1970-01-01');
		-- Set new end time
		SET @end = DATEADD(day, 3, @start);

		--IF (@Debug = 1)
		--	SELECT @start AS start, @tzOffset AS tzOffset, @LocalOffset AS LocalOffset, @Delta AS Delta;

		DECLARE @TimeSlot AS TABLE(
			Id INT IDENTITY(1,1)
			, StartDate DATETIME NOT NULL
			, EndDate DATETIME NOT NULL
			, Taken BIT NOT NULL DEFAULT 0
		);
		WITH Numbers AS(
			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT null)) AS Num
			FROM sys.tables
		)
		INSERT @TimeSlot (StartDate, EndDate, Taken)
		SELECT DATEADD(MINUTE, @length * (Num - 1), @start), DATEADD(MINUTE, @length * Num, @start), @UseNewScheduler
		FROM Numbers
		WHERE DATEADD(MINUTE, @length * Num, @start) < @end;

		--IF (@Debug = 1)
		--	SELECT * FROM @TimeSlot

		/*	Filter specialSlots
			Use TimeOfDay because we want to ignore the date portion of datetime */
		DECLARE @TimeSlotSpecialSlot AS TABLE(
			Id INT NOT NULL
			, StartDateTS DATETIME NOT NULL
			, EndDateTS DATETIME NOT NULL
			, Taken BIT NOT NULL DEFAULT (0)
			, Name nvarchar(100) NOT null
			, IsReadOnly BIT NULL
			, StartDateSS DATETIME NULL
			, EndDateSS DATETIME NULL
			, PatternStart DATETIME NULL
			, RecurrencePattern NVARCHAR(100) NULL
		);
		INSERT @TimeSlotSpecialSlot(Id, StartDateTS, EndDateTS, Taken, Name, IsReadOnly, StartDateSS, EndDateSS, PatternStart, RecurrencePattern)
		SELECT ts.Id, ts.StartDate, ts.EndDate, ts.Taken, ss.Name, ss.IsReadOnly, ss.StartDate, ss.EndDate
			,CAST(CAST(ss.StartDate AS date) AS DATETIME) + CAST(CAST(ts.StartDate AS TIME(3)) AS DATETIME)
			, ss.RecurrencePattern
		FROM @TimeSlot AS ts
		CROSS JOIN @SpecialSlot AS ss
		WHERE ss.StartDate < ts.EndDate
			AND ss.EndDate > ts.StartDate
			AND CAST(ss.StartDate AS TIME(3)) < CAST(ts.EndDate AS TIME(3))
			AND CAST(ss.EndDate AS TIME(3)) > CAST(ts.StartDate AS TIME(3));
	
		--IF (@Debug = 1)
		--	SELECT * FROM @TimeSlotSpecialSlot AS tsss ORDER BY tsss.Id;

		DECLARE @TimeSlotSpecialSlotOccur AS TABLE(
			Id INT NOT NULL
			, StartDateTS DATETIME NOT NULL
			, EndDateTS DATETIME NOT NULL
			, Taken BIT NULL DEFAULT (0)
			, Name nvarchar(100) NOT null
			, IsReadOnly BIT NULL
			, StartDateSS DATETIME NULL
			, EndDateSS DATETIME NULL
			, PatternStart DATETIME NULL
			, RecurrencePattern NVARCHAR(100) NULL
			, IsOccurrenceInRange BIT
		);
		INSERT @TimeSlotSpecialSlotOccur (Id, StartDateTS, EndDateTS, Taken, Name, IsReadOnly, StartDateSS, EndDateSS, PatternStart, RecurrencePattern, IsOccurrenceInRange)
		SELECT tsss.Id, tsss.StartDateTS, tsss.EndDateTS, tsss.Taken, tsss.Name, tsss.IsReadOnly, tsss.StartDateSS, tsss.EndDateSS, tsss.PatternStart, tsss.RecurrencePattern
			, dbo.PatientPortal_IsOccurrenceInRange(tsss.RecurrencePattern, tsss.PatternStart, tsss.StartDateTS, tsss.EndDateTS) AS IsOccurrenceInRange
		FROM @TimeSlotSpecialSlot AS tsss

		IF (@Debug = 1)
			SELECT * FROM @TimeSlotSpecialSlotOccur AS tssso

		UPDATE @TimeSlotSpecialSlotOccur
		SET Taken = 
			CASE
				WHEN IsOccurrenceInRange = 1 AND IsReadOnly = 1 THEN 1
				WHEN IsReadOnly = 1 AND Name = 'Available' AND (CAST(StartDateSS AS TIME(3)) <= CAST(StartDateTS AS TIME(3))) AND (CAST(EndDateSS AS TIME(3)) >= CAST(EndDateTS AS TIME(3))) THEN 0
			END

		--UPDATE @TimeSlotSpecialSlotOccur
		--SET 
	--END TRY
 --   BEGIN CATCH
	--	DECLARE @ErrorMessage NVARCHAR(4000);  
	--	DECLARE @ErrorSeverity INT;  
	--	DECLARE @ErrorState INT;  
  
	--	SET @ErrorMessage = ERROR_MESSAGE();  
	--	SET @ErrorSeverity = ERROR_SEVERITY();  
	--	SET @ErrorState = ERROR_STATE();

	--	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	--END CATCH;
--END
