USE [ElevateDev]
GO
/****** Object:  StoredProcedure [dbo].[PatientPortal_GetTimeSlots]    Script Date: 12/6/2016 11:49:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--USE [coreDev.SolutaHealth.com]
--GO
--/****** Object:  StoredProcedure [dbo].[PatientPortal_GetTimeSlots]    Script Date: 7/27/2016 2:19:15 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

ALTER PROC [dbo].[PatientPortal_GetTimeSlots]
(
	@start DATETIME
	, @end DATETIME
	, @AppointmentResourceID INT
	, @ClinicID INT
	, @PatientID INT
	, @RFVID INT
)
AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON;
		--SELECT * INTO dbo.RFV_RFVMain FROM shsql1.ElevateDev.dbo.RFV_RFVMain
		--SELECT * INTO dbo.Patients_Main FROM shsql1.ElevateDev.dbo.Patients_Main
		--SELECT * INTO dbo.Schedule_ScheduleEmployers FROM shsql1.ElevateDev.dbo.Schedule_ScheduleEmployers

		-- exec dbo.PatientPortal_GetTimeSlots '2016-09-12 00:00:00.000', '2016-09-12 11:00:59.999', 6500000, 1004057, 1, 1071002
		--DECLARE @start DATETIME = '2016-09-12 00:00:00.000';
		--DECLARE @end DATETIME = '2016-09-12 11:00:59.999';
		--DECLARE @AppointmentResourceID INT = 6500000;
		--DECLARE @ClinicID INT = 1004057;
		--DECLARE @PatientID INT = 1;
		--DECLARE @RFVID INT = 1071002;
		
		DECLARE @length INT = 0;
		DECLARE @maxAppts INT = 1;
		DECLARE @EmployerID INT;
		--DECLARE @queryStart DATETIME = GETDATE();
		--DECLARE @Debug INT = 1;
/****************************************************************************************************/		
/* #region Get Length of SubjectiveRFV */
		SELECT @length = AppointmentTimeMinutes
			, @maxAppts = MaxAppointments
		FROM dbo.RFV_RFVMain
		WHERE RFVID = @RFVID
		--SELECT @length AS ApptLength, @maxAppts AS MaxAppts--, @tzOffset AS tzOffset;

/* #region Get EmployerID*/
		SELECT @EmployerID = EmployerID
		FROM dbo.Patients_Main AS pm
		WHERE pm.PatientID = @PatientID

/* #region Create Appointments tables*/
		DECLARE @Appointments AS TABLE(
			StartDate DATETIME NOT NULL
			, EndDate DATETIME NOT NULL
			, RFVID INT NOT NULL
		);
		DECLARE @AppointmentsOverlap AS TABLE(
			StartDate DATETIME NOT NULL
			, EndDate DATETIME NOT NULL
			, RFVID INT NOT NULL
		);

/* #region Collect SpecialSlots */
		DECLARE @SpecialSlot AS TABLE(
			Name nvarchar(128) NOT null
			, IsReadOnly BIT NULL
			, StartDate DATETIME NULL
			, EndDate DATETIME NULL
			, RecurrencePattern NVARCHAR(256) NULL
		);
		INSERT @SpecialSlot(Name, IsReadOnly, StartDate, EndDate, RecurrencePattern)
		SELECT 
			tst.Description
			, tst.ReadOnly
			, srs.StartDate
			, srs.EndDate
			, srs.RecurrencePattern
		FROM dbo.Schedule_ResourceSchedules AS srs
		JOIN dbo.Types_ScheduleTypes AS tst
			ON tst.ScheduleTypeID = srs.ScheduleTypeID
		JOIN dbo.Schedule_ScheduleEmployers AS sse
			ON sse.ResourceScheduleID = srs.ResourceScheduleID
		WHERE srs.AppointmentResourceID = @AppointmentResourceID
			AND sse.EmployerID = @EmployerID
		--SELECT * FROM @SpecialSlot AS ss;
/****************************************************************************************************/
/*	#region Generate TimeSlots */
/* Only allow timeslots for the future. */
		DECLARE @Now DATETIME = GETDATE(); --DATEADD(minute, @Delta, GETDATE()) 

		IF (@Now > @start)
			SET @start = @Now;

		IF (@end < @start)
			SET @end = DATEADD(day, 3, @start);
		
		-- Truncate seconds
		SET @start = DATEADD(minute, DATEDIFF(minute, '1970-01-01', @start), '1970-01-01');

/* #region Collect Appointments */
		INSERT @Appointments(StartDate, EndDate, RFVID)
		SELECT StartTime
			, EndTime
			, RFVID
		FROM dbo.Schedule_Appointments
		WHERE AppointmentResourceID = @AppointmentResourceID
		AND StartTime >= @start
		AND StartTime <= @end
		--SELECT * FROM @Appointments AS a;

/* Create time slot loop variables*/
		-- Round to nearest 10 minutes
		DECLARE @startTime DATETIME = DATEADD(MINUTE, (60 - DATEPART(MINUTE, @start)) % 10, @start);
		DECLARE @endTime DATETIME;
		DECLARE @Taken BIT = 1;
		--SELECT @start AS StartTime, @EndTime as endDate--, @tzOffset AS tzOffset, @LocalOffset AS LocalOffset, @Delta AS Delta;

		DECLARE @TimeSlot AS TABLE(
			TimeSlotId INT IDENTITY(1,1)
			, StartDate DATETIME NULL
			, EndDate DATETIME NULL
			, Taken BIT NULL DEFAULT (1)
		);
		DECLARE @TimeSlotFinal AS TABLE(
			TimeSlotId INT IDENTITY(1,1)
			, StartDate DATETIME NULL
			, EndDate DATETIME NULL
			, Taken BIT NULL DEFAULT (1)
		);
		DECLARE @TimeSlotSpecialSlot AS TABLE(
			TimeSlotId INT NOT NULL
			, StartDateTS DATETIME NULL
			, EndDateTS DATETIME NULL
			, Taken BIT NULL DEFAULT (1)
			, Name nvarchar(100) null
			, IsReadOnly BIT NULL
			, StartDateSS DATETIME NULL
			, EndDateSS DATETIME NULL
			, PatternStart DATETIME NULL
			, PatternEnd DATETIME NULL
			, RecurrencePattern NVARCHAR(100) NULL
			, IsOccurrenceInRange BIT
		);
/****************************************************************************************************/
/* Loop over Time Slots incrementing @startTime*/
		DECLARE @i INT = 0;
		WHILE (DATEADD(MINUTE, @length, @startTime) <= @end)
		BEGIN
			SET @endTime = DATEADD(MINUTE, @length, @startTime);

			INSERT @TimeSlot(StartDate, EndDate, Taken)
			VALUES (@startTime, @endTime, @Taken);
			--SELECT *, @i AS i FROM @TimeSlot;

/*	Filter specialSlots. Use TimeOfDay because we want to ignore the date portion of datetime */
			WITH TimeSlotSpecialSlot AS
            (
				SELECT 
					ts.TimeSlotId, ts.StartDate AS StartDateTS, ts.EndDate AS EndDateTS, ts.Taken
					, ss.StartDate AS StartDateSS, ss.EndDate AS EndDateSS, ss.Name, ss.IsReadOnly
					,CAST(CAST(ss.StartDate AS date) AS DATETIME) + CAST(CAST(ts.StartDate AS TIME(3)) AS DATETIME) AS PatternStart
					,CAST(CAST(ts.EndDate AS date) AS DATETIME) + CAST(CAST(ss.EndDate AS TIME(3)) AS DATETIME) AS PatternEnd
					, ss.RecurrencePattern
				FROM @TimeSlot AS ts
				CROSS JOIN @SpecialSlot AS ss
				WHERE ss.StartDate < ts.EndDate
					AND ss.EndDate > ts.StartDate
					AND CAST(ss.StartDate AS TIME(3)) < CAST(ts.EndDate AS TIME(3))
					AND CAST(ss.EndDate AS TIME(3)) > CAST(ts.StartDate AS TIME(3))
				)
			INSERT @TimeSlotSpecialSlot(TimeSlotId, StartDateTS, EndDateTS, Taken
				, StartDateSS, EndDateSS, Name, IsReadOnly
				, PatternStart, PatternEnd, RecurrencePattern, IsOccurrenceInRange)
			SELECT tsss.TimeSlotId, tsss.StartDateTS, tsss.EndDateTS, tsss.Taken
				, tsss.StartDateSS, tsss.EndDateSS, tsss.Name, tsss.IsReadOnly
				, tsss.PatternStart, tsss.PatternEnd, tsss.RecurrencePattern
				, dbo.PatientPortal_IsOccurrenceInRange(tsss.RecurrencePattern, tsss.PatternStart, tsss.StartDateTS, tsss.EndDateTS) AS IsOccurrenceInRange
            FROM TimeSlotSpecialSlot AS tsss
			--SELECT * FROM @TimeSlotSpecialSlot AS tsss ORDER BY tsss.TimeSlotId;

			UPDATE @TimeSlotSpecialSlot
			SET Taken = CASE
					WHEN IsOccurrenceInRange = 1 AND IsReadOnly = 1 THEN 1
					WHEN IsOccurrenceInRange = 1 AND IsReadOnly = 0 --AND @UseNewScheduler = 0 AND Name = 'Available'
						AND CAST(StartDateSS AS TIME(3)) <= CAST(StartDateTs AS TIME(3))
						AND CAST(EndDateSS AS TIME(3)) >= CAST(EndDateTs AS TIME(3))
						THEN 0
				END
			--SELECT * FROM @TimeSlotSpecialSlot

			SET @endTime = COALESCE((SELECT MAX(PatternEnd) FROM @TimeSlotSpecialSlot WHERE IsOccurrenceInRange = 1 AND IsReadOnly = 1), @endTime);
			UPDATE @TimeSlot SET Taken = COALESCE((SELECT MAX(CAST(Taken AS TINYINT)) FROM @TimeSlotSpecialSlot), @Taken);
			--SELECT * FROM @TimeSlot AS ts;

/* Check if appointments overlap timeslot*/
			IF EXISTS (SELECT * FROM @TimeSlot AS ts WHERE Taken = 0)
			BEGIN
				INSERT @AppointmentsOverlap (StartDate, EndDate, RFVID)
				SELECT a.StartDate, a.EndDate, a.RFVID
				FROM @Appointments AS a
				CROSS JOIN @TimeSlot AS ts
				WHERE a.StartDate < ts.EndDate
					AND a.EndDate > ts.StartDate
				--SELECT * FROM @AppointmentsOverlap AS ao
			
				DECLARE @AppointmentCount INT = (SELECT COUNT(*) FROM @AppointmentsOverlap WHERE NOT (RFVID = @RFVID));
				DECLARE @AppointmentCountRFVID INT = (SELECT COUNT(*) FROM @AppointmentsOverlap WHERE RFVID = @RFVID);
				--SELECT @AppointmentCount, @AppointmentCountRFVID

				IF (@maxAppts > 1 AND @AppointmentCountRFVID > 0 AND (@AppointmentCountRFVID >= @maxAppts))
				BEGIN
					UPDATE @TimeSlot
					SET Taken = 1
			
					SET @endTime = (SELECT Min(EndDate) FROM @AppointmentsOverlap);
				END
				ELSE IF (@maxAppts > 1 AND @AppointmentCount > 0)
				BEGIN
					UPDATE @TimeSlot
					SET Taken = 1
				
					SET @endTime = (SELECT MAX(EndDate) FROM @AppointmentsOverlap);
				END
				ELSE IF (@maxAppts = 1 AND (@AppointmentCountRFVID > 0 OR @AppointmentCount > 0))
				BEGIN
					UPDATE @TimeSlot
					SET Taken = 1
				
					SET @endTime = (SELECT MAX(EndDate) FROM @AppointmentsOverlap);
				END
				--SELECT * FROM @TimeSlot;
			END
/* Save time slot if available otherwise discard*/
			IF EXISTS (SELECT * FROM @TimeSlot WHERE Taken = 0)
				INSERT @TimeSlotFinal (StartDate, EndDate, Taken)
				SELECT StartDate, EndDate, Taken FROM @TimeSlot;
			--SELECT StartDate AS SDF, EndDate AS EDF, Taken AS TF FROM @TimeSlotFinal;
/* Clean up */
			DELETE @TimeSlot;
			DELETE @TimeSlotSpecialSlot;
			DELETE @AppointmentsOverlap;

			SET @startTime = DATEADD(MINUTE, (60 - DATEPART(MINUTE, @endTime)) % 10, @endTime);
			SET @i = @i + 1
		END
		
		SELECT * FROM @TimeSlotFinal AS tsf;
	END TRY
    BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
  
		SET @ErrorMessage = ERROR_MESSAGE();
		SET @ErrorSeverity = ERROR_SEVERITY();
		SET @ErrorState = ERROR_STATE();

		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH;
END
