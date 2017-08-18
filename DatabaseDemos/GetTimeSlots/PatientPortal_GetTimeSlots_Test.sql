USE [ElevateDev]
GO

SELECT  tst.Description, tst.ReadOnly, srs.StartDate, srs.EndDate,
        srs.RecurrencePattern
FROM    dbo.Schedule_ResourceSchedules AS srs
        JOIN dbo.Types_ScheduleTypes AS tst ON tst.ScheduleTypeID = srs.ScheduleTypeID
WHERE srs.AppointmentResourceID = 6500000

SELECT  *--AppointmentID, StartTime, EndTime, RFVID
FROM    dbo.Schedule_Appointments
WHERE AppointmentResourceID = 6500000
AND starttime >= '2016-09-12 00:00:00.000'
ORDER BY StartTime
GO
--DECLARE @Now datetime = GETDATE()
--INSERT dbo.Schedule_Appointments (StartTime, EndTime, RFVID, AppointmentResourceID, ChartID, AppointmentStatusID, Body, ScheduledBy, ScheduledDate, LastUpdatedBy, LastUpdated)
--VALUES ('2016-09-12 08:20:00.000', '2016-09-12 08:40:00.000', 1071004, 6500000, 101, 1, 'Health Screening Follow-Up', '248CFD2A-329B-4893-8332-B254D076C609', @Now, '248CFD2A-329B-4893-8332-B254D076C609', @Now)

SELECT * FROM dbo.RFV_RFVMain AS rrm
DELETE dbo.Schedule_Appointments WHERE AppointmentID = 6800146
GO


DECLARE @RC INT
DECLARE @start DATETIME = '2016-09-12 08:00:00'
DECLARE @end DATETIME = '2016-09-15 23:00:00'
DECLARE @AppointmentResourceID INT = 6500000;
DECLARE @ClinicID INT = 1004057
DECLARE @PatientID INT = 1
DECLARE @RFVID INT = 1071002

EXECUTE @RC = [dbo].[PatientPortal_GetTimeSlots] @start, @end, @AppointmentResourceID, @ClinicID, @PatientID, @RFVID
GO

DECLARE @RC INT
DECLARE @start DATETIME = '2016-09-12'
DECLARE @end DATETIME = '2016-09-16'
DECLARE @AppointmentResourceID INT = 6500000;
DECLARE @ClinicID INT = 1004057
DECLARE @PatientID INT = 2
DECLARE @RFVID INT = 1071003

EXECUTE @RC = [dbo].[PatientPortal_GetTimeSlots] @start, @end, @AppointmentResourceID, @ClinicID, @PatientID, @RFVID
GO

DECLARE @RC INT
DECLARE @start DATETIME = '2016-09-12'
DECLARE @end DATETIME = '2016-09-14'
DECLARE @AppointmentResourceID INT = 6500000;
DECLARE @ClinicID INT = 1004057
DECLARE @PatientID INT = 1
DECLARE @RFVID INT = 1071004

EXECUTE @RC = [dbo].[PatientPortal_GetTimeSlots] @start, @end, @AppointmentResourceID, @ClinicID, @PatientID, @RFVID
GO

DECLARE @RC INT
DECLARE @start DATETIME = '2016-09-12'
DECLARE @end DATETIME = '2016-09-16'
DECLARE @AppointmentResourceID INT = 6500000;
DECLARE @ClinicID INT = 1004057
DECLARE @PatientID INT = 2
DECLARE @RFVID INT = 1071002

EXECUTE @RC = [dbo].[PatientPortal_GetTimeSlots] @start, @end, @AppointmentResourceID, @ClinicID, @PatientID, @RFVID
GO
