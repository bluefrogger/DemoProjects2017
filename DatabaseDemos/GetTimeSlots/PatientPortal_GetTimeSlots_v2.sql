--USE [coreDev.SolutaHealth.com]
--GO
--/****** Object:  StoredProcedure [dbo].[PatientPortal_GetTimeSlots]    Script Date: 7/27/2016 2:19:15 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

--create PROC [dbo].[PatientPortal_GetTimeSlots]
--(
--	@start DATETIME
--	, @end DATETIME
--	, @physicianID INT
--	, @practiceID INT
--  , @practiceGroupID INT
--  , @subjectiveRFVID INT
--)
--AS BEGIN
--	BEGIN TRY
--		SET NOCOUNT ON;

		DECLARE @start DATETIME = '2013-09-30 00:00:00.000';
		DECLARE @end DATETIME = '2013-09-30 23:59:59.999';
		DECLARE @physicianID INT = 1088051;
		DECLARE @practiceID INT = 1004049;
		DECLARE @practiceGroupID INT;
		DECLARE @subjectiveRFVID INT = 1071002;

		DECLARE @queryStart DATETIME = GETDATE();
		DECLARE @Debug INT = 1;
/****************************************************************************************************/		
		DECLARE @length INT = 0;
		DECLARE @maxAppts INT = 1;

/* #region Get Length of SubjectiveRFV */
		SELECT @length = dbo.sh_SubjectiveRFVs.AppointmentTimeMinutes
			, @maxAppts = dbo.sh_SubjectiveRFVs.MaxAppointments
		FROM dbo.sh_SubjectiveRFVs
		WHERE dbo.sh_SubjectiveRFVs.SubjectiveRFVID = @SubjectiveRFVID
		SELECT @length AS ApptLength, @maxAppts AS MaxAppts

/* #region Collect Appointments */
		DECLARE @Appointments AS TABLE(
			StartDate DATETIME NOT NULL
			, EndDate DATETIME NOT NULL
		);
		DECLARE @AppointmentsOverlap AS TABLE(
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
		BEGIN
			INSERT @Appointments (StartDate, EndDate)
			VALUES ('2016-07-27 15:00:00', '2016-07-25 17:00:00');
			SELECT * FROM @Appointments AS a;
		END

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
				,('Lunch',	1, '2016-07-14 12:00:00.000', '2016-08-14 13:00:00.000', 'FREQ=WEEKLY;BYDAY=SU,MO,TU,WE,TH,SA')
				,('Vacation', 1, '2016-07-20 08:00:00.000', '2016-07-27 17:00:00.000', 'FREQ=WEEKLY;BYDAY=SU,MO,TU,WE,TH,SA');
			--SELECT * FROM @SpecialSlot AS ss;
		END;
/****************************************************************************************************/
/*	#region Generate TimeSlots
	If using new scheduler, determine initial starting point based on first Available SpecialSlot in db result.
	Result must be ordered by StartDate above.
*/
		--IF (@UseNewScheduler = 1)
		--BEGIN
			SELECT @start = COALESCE(MIN(StartDate), @start)
			FROM @SpecialSlot
			WHERE Name = 'Available';
		--END
		--SELECT @UseNewScheduler AS UseNewScheduler, @start AS start

/* Only allow timeslots for the future. */
		--DECLARE @LocalOffset INT = ABS(DATEDIFF(minute, GETUTCDATE(), GETDATE()));
		--DECLARE @Delta INT = (@tzOffset - @LocalOffset) * (-1);
		DECLARE @NowClinic DATETIME = GETDATE(); --DATEADD(minute, @Delta, GETDATE()) 

		IF (@NowClinic > @start)
			SET @start = @NowClinic;

		-- Truncate seconds
		SET @start = DATEADD(minute, DATEDIFF(minute, '1970-01-01', @start), '1970-01-01');
		-- Set new end date
		SET @end = DATEADD(day, 3, @start);
		-- Round to nearest 10 minutes
		DECLARE @startTime DATETIME = DATEADD(MINUTE, (60 - DATEPART(MINUTE, @start)) % 10, @start);
		DECLARE @endTime DATETIME;
		DECLARE @Taken BIT = 1;
		--SELECT @start AS start, @end as endDate, @tzOffset AS tzOffset, @LocalOffset AS LocalOffset, @Delta AS Delta;

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
						AND CAST(EndDateSS AS TIME(3)) >= CAST(StartDateTS AS TIME(3))
						THEN 0
				END
			--SELECT * FROM @TimeSlotSpecialSlot

			SET @endTime = COALESCE((SELECT MAX(PatternEnd) FROM @TimeSlotSpecialSlot WHERE IsOccurrenceInRange = 1 AND IsReadOnly = 1), @endTime);
			UPDATE @TimeSlot SET Taken = COALESCE((SELECT MAX(CAST(Taken AS TINYINT)) FROM @TimeSlotSpecialSlot), @Taken);
			--SELECT * FROM @TimeSlot AS ts;
			
/* Check if appointments overlap timeslot*/
			IF EXISTS (SELECT * FROM @TimeSlot AS ts WHERE Taken = 0)
			BEGIN
				INSERT @AppointmentsOverlap (StartDate, EndDate)
				SELECT a.StartDate, a.EndDate
				FROM @Appointments AS a
				CROSS JOIN @TimeSlot AS ts
				WHERE a.StartDate < ts.EndDate
					AND a.EndDate > ts.StartDate
				--SELECT * FROM @AppointmentsOverlap AS ao
			
				DECLARE @AppointmentCount INT = (SELECT COUNT(*) FROM @AppointmentsOverlap);

				IF (@AppointmentCount > 0 AND @maxAppts > 1 AND (@AppointmentCount >= @maxAppts))
				BEGIN
					UPDATE @TimeSlot
					SET Taken = 1
			
					SET @endTime = (SELECT Min(EndDate) FROM @AppointmentsOverlap);
				END
				ELSE IF (@AppointmentCount > 0)
				BEGIN
					UPDATE @TimeSlot
					SET Taken = 1
				
					SET @endTime = (SELECT MAX(EndDate) FROM @AppointmentsOverlap);
				END

				--IF (@Debug = 1)
				--	SELECT * FROM @TimeSlot;
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
--	END TRY
--    BEGIN CATCH
--		DECLARE @ErrorMessage NVARCHAR(4000);
--		DECLARE @ErrorSeverity INT;
--		DECLARE @ErrorState INT;
  
--		SET @ErrorMessage = ERROR_MESSAGE();
--		SET @ErrorSeverity = ERROR_SEVERITY();
--		SET @ErrorState = ERROR_STATE();

--		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
--	END CATCH;
--END

SELECT * FROM @TimeSlotFinal AS tsf