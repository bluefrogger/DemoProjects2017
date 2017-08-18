
CREATE PROC [dbo].[PatientPortal_GetTimeSlots]
(
	@start DATETIME
	, @end DATETIME
	, @physicianID INT
	, @practiceID INT
	, @practiceGroupID INT
	, @subjectiveRFVID INT
	, @Debug INT = 0
)
AS BEGIN
	BEGIN TRY
		SET NOCOUNT ON;

	/***** Setup variables and result sets *****/
		DECLARE @queryStart DATETIME = GETDATE();
		DECLARE @length INT = 0;
		DECLARE @maxAppts INT = 1;
		DECLARE @TimeZoneName NVARCHAR(128);
		DECLARE @UseNewScheduler BIT;
		DECLARE @tzOffset INT = 300; --Central

		/* Get TimeZone & NewScheduler properties for each practice */
		SELECT @TimeZoneName = dbo.sh_TimeZones.TimeZoneName
			, @UseNewScheduler = COALESCE(dbo.sh_PracticePreferences.UseNewScheduler, 1)
		FROM dbo.sh_PracticePreferences
		INNER JOIN dbo.sh_TimeZones
			ON dbo.sh_PracticePreferences.TimeZoneID = dbo.sh_TimeZones.TimeZoneID
		WHERE (dbo.sh_PracticePreferences.PracticeID = @practiceID);

		IF (@TimeZoneName IS NOT NULL)
			SET @tzOffset = dbo.GetUtcOffset(@TimeZoneName);

		/* Get Length of SubjectiveRFV */
		SELECT @length = dbo.sh_SubjectiveRFVs.AppointmentTimeMinutes
			, @maxAppts = dbo.sh_SubjectiveRFVs.MaxAppointments
		FROM dbo.sh_SubjectiveRFVs
		WHERE dbo.sh_SubjectiveRFVs.SubjectiveRFVID = @SubjectiveRFVID
		AND (dbo.sh_SubjectiveRFVs.PracticeID = @PracticeID 
			OR dbo.sh_SubjectiveRFVs.PracticeGroupID = @PracticeGroupID
			);

		IF (@Debug = 1)
			SELECT @length AS ApptLength, @maxAppts AS MaxAppts, @tzOffset AS tzOffset;

		/* Get available appointment start and end dates */
		DECLARE @Appointments AS TABLE(
			StartDate DATETIME NOT NULL
			, EndDate DATETIME NOT NULL
			, SubjectiveRFVID INT NOT NULL
		);
		DECLARE @AppointmentsOverlap AS TABLE(
			StartDate DATETIME NOT NULL
			, EndDate DATETIME NOT NULL
			, SubjectiveRFVID INT NOT NULL
		);

		INSERT @Appointments(StartDate, EndDate, SubjectiveRFVID)
		SELECT sa.StartDate
			, sa.EndDate
			, sa.SubjectiveRFVID
		FROM dbo.sa_AppointmentResources as sar
		INNER JOIN dbo.sa_Appointments AS sa
			ON sar.AppointmentID = sa.AppointmentID
		INNER JOIN dbo.sa_Resources AS sr
			ON sar.AppointmentResourceID = sr.ResourceID
		WHERE (sr.PhysicianID = @PhysicianID)
		AND (sr.PracticeID = @PracticeID)
		AND (sa.StartDate >= CONVERT(datetime, @start))
		AND (sa.StartDate <= CONVERT(datetime, @end))

		IF (@Debug = 1)
		BEGIN
			INSERT @Appointments (StartDate, EndDate)
			VALUES ('2016-07-25 10:00:00', '2016-07-25 04:00:00');
			SELECT * FROM @Appointments AS a;
		END

		/* Get special slots start and end dates and pattern*/
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
			SELECT * FROM @SpecialSlot AS ss;
		END
		
		/*	
			Generate time slots based on patient inputted start and end dates.
			Optional: If using new scheduler, determine initial starting point based on first Available SpecialSlot in db result.
			Result must be ordered by StartDate above.
		*/
		IF (@UseNewScheduler = 1)
		BEGIN
			SELECT @start = COALESCE(MIN(StartDate), @start)
			FROM @SpecialSlot
			WHERE Name = 'Available';
		END;
		
		IF (@Debug = 1)
			SELECT @UseNewScheduler AS UseNewScheduler, @start AS start

		/* Only allow timeslots for the future. */
		DECLARE @LocalOffset INT = ABS(DATEDIFF(minute, GETUTCDATE(), GETDATE()));
		DECLARE @Delta INT = (@tzOffset - @LocalOffset) * (-1);
		DECLARE @NowClinic DATETIME = DATEADD(minute, @Delta, GETDATE()) -- GETDATE();

		IF (@NowClinic > @start)
			SET @start = @NowClinic;
		

		/* Truncate seconds */
		SET @start = DATEADD(minute, DATEDIFF(minute, '1970-01-01', @start), '1970-01-01');
		
		/* Set new end date */
		SET @end = DATEADD(day, 3, @start);

		/* Round to nearest 10 minutes */
		DECLARE @startTime DATETIME = DATEADD(MINUTE, (60 - DATEPART(MINUTE, @start)) % 10, @start);
		DECLARE @endTime DATETIME;

		/* Set if generated time slot is taken or not */
		DECLARE @Taken BIT = 1;
		
		IF (@Debug = 1)
			SELECT @start AS start, @end as endDate, @tzOffset AS tzOffset, @LocalOffset AS LocalOffset, @Delta AS Delta;

		/* Temporary result tables */
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
		
	/***** Main Loop *****/
		DECLARE @i INT = 0;
		WHILE (DATEADD(MINUTE, @length, @startTime) <= @end)
		BEGIN
			SET @endTime = DATEADD(MINUTE, @length, @startTime);

			INSERT @TimeSlot(StartDate, EndDate, Taken)
			VALUES (@startTime, @endTime, @Taken);
			
			IF (@Debug = 1)
				SELECT *, @i AS i FROM @TimeSlot;

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
			
			IF (@Debug = 1)
				SELECT * FROM @TimeSlotSpecialSlot AS tsss ORDER BY tsss.TimeSlotId;			

			UPDATE @TimeSlotSpecialSlot
			SET Taken = CASE
					WHEN IsOccurrenceInRange = 1 AND IsReadOnly = 1 THEN 1
					WHEN IsOccurrenceInRange = 1 AND IsReadOnly = 0 AND @UseNewScheduler = 0 AND Name = 'Available'
						AND CAST(StartDateSS AS TIME(3)) <= CAST(StartDateTs AS TIME(3))
						AND CAST(EndDateSS AS TIME(3)) >= CAST(EndDateTS AS TIME(3))
						THEN 0
				END
			
			IF (@Debug = 1)
				SELECT * FROM @TimeSlotSpecialSlot

			SET @endTime = COALESCE((SELECT MAX(PatternEnd) FROM @TimeSlotSpecialSlot WHERE IsOccurrenceInRange = 1 AND IsReadOnly = 1), @endTime);
			UPDATE @TimeSlot SET Taken = COALESCE((SELECT MAX(CAST(Taken AS TINYINT)) FROM @TimeSlotSpecialSlot), @Taken);
			
			IF (@Debug = 1)
				SELECT * FROM @TimeSlot AS ts;
			
			/* Check if appointments overlap timeslot*/
			IF EXISTS (SELECT * FROM @TimeSlot AS ts WHERE Taken = 0)
			BEGIN
				INSERT @AppointmentsOverlap (StartDate, EndDate, SubjectiveRFVID)
				SELECT a.StartDate, a.EndDate, a.SubjectiveRFVID
				FROM @Appointments AS a
				CROSS JOIN @TimeSlot AS ts
				WHERE a.StartDate < ts.EndDate
					AND a.EndDate > ts.StartDate
				
				IF (@Debug = 1)
					SELECT * FROM @AppointmentsOverlap AS ao
			
				DECLARE @AppointmentCount INT = (SELECT COUNT(*) FROM @AppointmentsOverlap);
				DECLARE @AppointmentCountRFVID INT = (SELECT COUNT(*) FROM @AppointmentsOverlap WHERE SubjectiveRFVID = @subjectiveRFVID);

				IF (@maxAppts > 1 AND @AppointmentCountRFVID > 0 AND (@AppointmentCountRFVID >= @maxAppts))
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

				IF (@Debug = 1)
					SELECT * FROM @TimeSlot;
			END

			/* Save time slot if available otherwise discard*/
			IF EXISTS (SELECT * FROM @TimeSlot WHERE Taken = 0)
				INSERT @TimeSlotFinal (StartDate, EndDate, Taken)
				SELECT StartDate, EndDate, Taken FROM @TimeSlot;
			
			IF (@Debug = 1)
				SELECT StartDate AS SDF, EndDate AS EDF, Taken AS TF FROM @TimeSlotFinal;

			/* Clean up variables*/
			DELETE @TimeSlot;
			DELETE @TimeSlotSpecialSlot;
			DELETE @AppointmentsOverlap;

			SET @startTime = DATEADD(MINUTE, (60 - DATEPART(MINUTE, @endTime)) % 10, @endTime);
			SET @i = @i + 1
		END

		IF (@Debug = 1)
			SELECT * FROM @TimeSlotFinal AS tsf
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

