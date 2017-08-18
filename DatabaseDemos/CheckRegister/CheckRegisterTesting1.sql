SELECT * FROM dbo.ssrs_checkreg_queue WHERE daterequested > CONVERT(DATE, GETDATE()) AND GRNBR = '236'

UPDATE dbo.SSRS_CheckReg_Queue
SET InProcess = 0, Processed = 0, batchid = null
WHERE SSRSCheckRegQueueID = 1012867

SELECT * FROM SSRS_CheckReg_CJP WHERE runid = 'ADA9B41D-07BD-4794-B233-0C373084773C'

SELECT * FROM dbo.SSRS_CheckReg_CJP2
SELECT * FROM dbo.SSRS_CheckReg_GRP2
SELECT * FROM dbo.SSRS_CheckReg_Patient2
SELECT * FROM dbo.SSRS_CheckReg_CLMH2

SELECT * FROM dbo.CheckRegisterTargetQueue
SELECT * FROM dbo.CheckRegisterInitQueue
GO
	
		
DECLARE @PUNBR NVARCHAR(3) = '002';
DECLARE @GRNBR NVARCHAR(3) = '236';
DECLARE @StartDate NVARCHAR(8) = '20160801';
DECLARE @EndDate NVARCHAR(8) = '20160826';
DECLARE @ChkType01 CHAR(1) = '1';
DECLARE @ChkType02 CHAR(1) = '0';
DECLARE @ChkType03 CHAR(1) = '3';
DECLARE @ChkType04 CHAR(1) = '0';

SET NOCOUNT ON;
DECLARE @RunID NVARCHAR(50) = CAST(NEWID() AS NVARCHAR(50));
DECLARE @conversation_handle UNIQUEIDENTIFIER;
DECLARE @message_body XML = (
	SELECT @PUNBR AS PUNBR, @GRNBR AS GRNBR, @StartDate AS StartDate, @EndDate AS EndDate
		, @ChkType01 AS ChkType01, @ChkType02 AS ChkType02, @ChkType03 AS ChkType03, @ChkType04 AS ChkType04, @RunID AS RunID
	FOR XML PATH(''), ROOT('CheckRegister')
)

BEGIN DIALOG CONVERSATION @conversation_handle
	FROM SERVICE CheckRegisterInitService
	TO SERVICE 'CheckRegisterTargetService'
	ON CONTRACT CheckRegisterContract
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @conversation_handle
	MESSAGE TYPE CheckRegisterMessage(@message_body);

EXEC msdb.dbo.sp_start_job @job_name = 'BC_jb_SSRS_ProcessCheckRegQueue2';

DECLARE @TimeOut int = 320;
DECLARE @StartTime DATETIME = GETDATE();

WHILE (1 = 1)
BEGIN
	WAITFOR DELAY '00:00:00.400';
	IF EXISTS (SELECT * FROM dbo.SSRS_CheckReg_CJP2 WHERE RunID = @RunID)
	BEGIN
		SELECT  
			CJP.FISSDATE AS ChkIssueDtMMDDYYYY
				, RTRIM(LTRIM(CJP.CHECKNO)) AS ChkNo
				, CJP.CHECKTYPE AS CheckType
				, CJP.TYPE AS ChkType
				, GRP.NAME AS GrpName
				, CJP.PUNBR AS GrpPolUnd
				, CJP.GRNBR AS GrpNo
				, CJP.DEPT AS EmpDept
				, CJP.FCINCDT AS ClmIncDtMMDDYYYY
				, CJP.POLICY AS ClmType
				, CJP.CLAIM AS ClmNo
				, CJP.ESSN AS EmpSSN
				, CJP.SEQ AS PatSeq
				, PATIENT.LNAME AS InsLname
				, PATIENT.FTNAME AS InsFname
				, PATIENT.MINIT AS InsMI
				, PATIENT_1.LNAME AS PatLname
				, PATIENT_1.FTNAME AS PatFname
				, PATIENT_1.MINIT AS PatMI
				, CJP.PAYEE AS PayeeTaxID
				, CJP.PNAME AS PayeeName
				, CJP.PAY AS PmtAmt
		FROM  dbo.SSRS_CheckReg_CJP2 AS CJP
		LEFT OUTER JOIN SSRS_CheckReg_GRP2 AS GRP ON CJP.PUNBR = GRP.PUNBR
													AND CJP.GRNBR = GRP.GRNBR
													AND CJP.RunID = GRP.RunID
		LEFT OUTER JOIN SSRS_CheckReg_Patient2 AS PATIENT ON CJP.ESSN = PATIENT.ESSN
													AND CJP.GRNBR = PATIENT.GRNBR
													AND CJP.PUNBR = PATIENT.PUNBR
													AND PATIENT.SEQ = '00'
													AND CJP.RunID = PATIENT.RunID
		LEFT OUTER JOIN SSRS_CheckReg_Patient2 AS PATIENT_1 ON CJP.SEQ = PATIENT_1.SEQ
													AND CJP.ESSN = PATIENT_1.ESSN
													AND CJP.GRNBR = PATIENT_1.GRNBR
													AND CJP.PUNBR = PATIENT_1.PUNBR
													AND CJP.RunID = PATIENT_1.RunID
		WHERE CJP.RunID = @RunID
			AND CJP.PUNBR = @PUNBR
			AND CJP.GRNBR = @GRNBR  
			AND CJP.TYPE IN (@ChkType01, @ChkType02, @ChkType03, @ChkType04)
		ORDER BY CJP.FISSDATE
				, CJP.CHECKNO;
		BREAK;
	END
	ELSE IF (DATEDIFF(SECOND, @StartTime, GETDATE()) > @TimeOut)
		BREAK;
	ELSE
		CONTINUE;
END
GO

DECLARE @PUNBR NVARCHAR(3) = '002';
DECLARE @GRNBR NVARCHAR(3) = '236';
DECLARE @StartDate NVARCHAR(8) = '20160801';
DECLARE @EndDate NVARCHAR(8) = '20160826';
DECLARE @ChkType01 CHAR(1) = '1';
DECLARE @ChkType02 CHAR(1) = '0';
DECLARE @ChkType03 CHAR(1) = '3';
DECLARE @ChkType04 CHAR(1) = '0';

DECLARE @message_body XML = (
	SELECT @PUNBR AS PUNBR, @GRNBR AS GRNBR, @StartDate AS StartDate, @EndDate AS EndDate
		, @ChkType01 AS ChkType01, @ChkType02 AS ChkType02, @ChkType03 AS ChkType03, @ChkType04 AS ChkType04
	FOR XML PATH(''), ROOT('CheckRegister')
);

	--SEND ON CONVERSATION '67A84D01-3F5F-E611-969F-005056807664'
	--	MESSAGE TYPE CheckRegisterMessage(@message_body);

DECLARE @conversation_handle UNIQUEIDENTIFIER

BEGIN DIALOG CONVERSATION @conversation_handle
	FROM SERVICE CheckRegisterInitService
	TO SERVICE 'CheckRegisterTargetService'
	ON CONTRACT CheckRegisterContract
	WITH ENCRYPTION = OFF;

SEND ON CONVERSATION @conversation_handle
	MESSAGE TYPE CheckRegisterMessage(@message_body);
GO


DECLARE @PUNBR NVARCHAR(3) = '002';
DECLARE @GRNBR NVARCHAR(3) = '236';
DECLARE @StartDate datetime = '2016-08-01';
DECLARE @EndDate datetime = '2016-08-26';
DECLARE @ChkType01 CHAR(1) = '1';
DECLARE @ChkType02 CHAR(1) = '0';
DECLARE @ChkType03 CHAR(1) = '3';
DECLARE @ChkType04 CHAR(1) = '0';
DECLARE @runid UNIQUEIDENTIFIER = '0207105C-3567-4D8C-91D5-C1DECADA1B12'

--SELECT * FROM dbo.SSRS_CheckReg_CJP2 WHERE runid = @runid
--SELECT * FROM SSRS_CheckReg_GRP2 WHERE runid = @runid
--SELECT * FROM SSRS_CheckReg_Patient2 WHERE runid = @runid
--EXEC [dbo].[SSRS_CheckRegisterForApprovals2] @PUNBR = @PUNBR, @GRNBR = @GRNBR, @StartDate = @StartDate, @EndDate = @EndDate, @ChkType01 = @ChkType01, @ChkType02 = @ChkType02, @ChkType03 = @ChkType03, @ChkType04 = @ChkType04;

SELECT  
				CJP.FISSDATE AS ChkIssueDtMMDDYYYY
					, RTRIM(LTRIM(CJP.CHECKNO)) AS ChkNo
					, CJP.CHECKTYPE AS CheckType
					, CJP.TYPE AS ChkType
					, GRP.NAME AS GrpName
					, CJP.PUNBR AS GrpPolUnd
					, CJP.GRNBR AS GrpNo
					, CJP.DEPT AS EmpDept
					, CJP.FCINCDT AS ClmIncDtMMDDYYYY
					, CJP.POLICY AS ClmType
					, CJP.CLAIM AS ClmNo
					, CJP.ESSN AS EmpSSN
					, CJP.SEQ AS PatSeq
					, PATIENT.LNAME AS InsLname
					, PATIENT.FTNAME AS InsFname
					, PATIENT.MINIT AS InsMI
					, PATIENT_1.LNAME AS PatLname
					, PATIENT_1.FTNAME AS PatFname
					, PATIENT_1.MINIT AS PatMI
					, CJP.PAYEE AS PayeeTaxID
					, CJP.PNAME AS PayeeName
					, CJP.PAY AS PmtAmt
			FROM  dbo.SSRS_CheckReg_CJP2 AS CJP
			LEFT OUTER JOIN SSRS_CheckReg_GRP2 AS GRP ON CJP.PUNBR = GRP.PUNBR
														AND CJP.GRNBR = GRP.GRNBR
														AND CJP.RunID = GRP.RunID
			LEFT OUTER JOIN SSRS_CheckReg_Patient2 AS PATIENT ON CJP.ESSN = PATIENT.ESSN
														AND CJP.GRNBR = PATIENT.GRNBR
														AND CJP.PUNBR = PATIENT.PUNBR
														AND PATIENT.SEQ = '00'
														AND CJP.RunID = PATIENT.RunID
			LEFT OUTER JOIN SSRS_CheckReg_Patient2 AS PATIENT_1 ON CJP.SEQ = PATIENT_1.SEQ
														AND CJP.ESSN = PATIENT_1.ESSN
														AND CJP.GRNBR = PATIENT_1.GRNBR
														AND CJP.PUNBR = PATIENT_1.PUNBR
														AND CJP.RunID = PATIENT_1.RunID
			WHERE CJP.RunID = @RunID
				AND CJP.PUNBR = @PUNBR
				AND CJP.GRNBR = @GRNBR  
				AND CJP.TYPE IN (@ChkType01, @ChkType02, @ChkType03, @ChkType04)
			ORDER BY CJP.FISSDATE
					, CJP.CHECKNO;
GO



ALTER PROC dbo.SSRS_CheckRegisterTargetServiceReceive
AS
begin
	-- Declare the table variable to hold the XML messages
	DECLARE @messages TABLE( 
		conversation_handle UNIQUEIDENTIFIER
		, message_type_name sysname
		, message_body NVARCHAR(1000)
		, message_data xml
	);

	-- Receive all the messages for the next conversation_handle from the queue into the table variable
	RECEIVE	TOP(1)
		conversation_handle
		, message_type_name
		, message_body
		, CAST(message_body as xml)
	FROM dbo.CheckRegisterTargetQueue
	INTO @messages;

	-- Parse the XML from the table variable
	SELECT
		conversation_handle
		, message_type_name
		, message_body
		, message_data
		, message_data.value('(/CheckRegister/PUNBR)[1]', 'NVARCHAR(3)' ) AS PUNBR
		, message_data.value('(/CheckRegister/GRNBR)[1]', 'NVARCHAR(3)') AS GRNBR
		, message_data.value('(/CheckRegister/StartDate)[1]', 'DATETIME' ) AS StartDate
		, message_data.value('(/CheckRegister/EndDate)[1]', 'DATETIME' ) AS EndDate
		, message_data.value('(/CheckRegister/ChkType01)[1]', 'CHAR(1)' ) AS ChkType01
		, message_data.value('(/CheckRegister/ChkType02)[1]', 'CHAR(1)' ) AS ChkType02
		, message_data.value('(/CheckRegister/ChkType03)[1]', 'CHAR(1)' ) AS ChkType03
		, message_data.value('(/CheckRegister/ChkType04)[1]', 'CHAR(1)' ) AS ChkType04
		, message_data.value('(/CheckRegister/RunID)[1]', 'CHAR(1)' ) AS RunID
	FROM @messages;
END


DECLARE @conversation_handle UNIQUEIDENTIFIER;

DECLARE curConv CURSOR FOR
	SELECT ce.conversation_handle FROM sys.conversation_endpoints AS ce WHERE far_service NOT IN ('CheckRegisterNotificationService','http://schemas.microsoft.com/SQL/Notifications/EventNotificationService');

OPEN curConv;
FETCH NEXT FROM curConv INTO @conversation_handle;

WHILE (@@FETCH_STATUS = 0)
BEGIN
	END CONVERSATION @conversation_handle;
	FETCH NEXT FROM curConv INTO @conversation_handle;
END

CLOSE curConv;
DEALLOCATE curConv;
GO

	SELECT * FROM sys.conversation_endpoints AS ce --WHERE NOT (state_desc = 'CLOSED')
	SELECT * FROM sys.event_notifications AS en
	SELECT * FROM sys.services AS s
	SELECT * FROM sys.transmission_queue AS tq
	SELECT * FROM sys.dm_broker_queue_monitors
	SELECT * FROM msdb.dbo.Ssislog AS s
GO


DECLARE @conversation_handle UNIQUEIDENTIFIER;
DECLARE @message_type_name sysname;
DECLARE @message_body XML;
	
RECEIVE
	@conversation_handle = conversation_handle
	, @message_type_name = @message_type_name
	, CAST(message_body as xml)
FROM dbo.CheckRegisterTargetQueue

DECLARE @messages2 TABLE
( message_data xml );

RECEIVE cast(message_body as xml)
FROM dbo.CheckRegisterNotificationQueue
INTO @messages2;


ALTER QUEUE CheckRegisterTargetQueue WITH ACTIVATION (STATUS = OFF);
ALTER QUEUE CheckRegisterTargetQueue WITH ACTIVATION (STATUS = ON, EXECUTE AS self);

--[NT AUTHORITY\NETWORK SERVICE]

RAISERROR (N'Test ERRORLOG Event Notifications', 10, 1) WITH LOG;
GO

--SELECT * FROM dbo.CheckRegisterNotificationQueue
SELECT * FROM dbo.CheckRegisterTargetQueue
SELECT * FROM dbo.CheckRegisterInitQueue

SELECT * FROM dbo.ssislog AS s
--	TRUNCATE TABLE dbo.Ssislog

INSERT dbo.ssislog (StartDate, PackageName)
VALUES ('2000-01-02 00:00:00', '');


TRUNCATE TABLE dbo.SSRS_CheckReg_CJP2
TRUNCATE TABLE dbo.SSRS_CheckReg_GRP2 
TRUNCATE TABLE dbo.SSRS_CheckReg_Patient2
TRUNCATE TABLE dbo.SSRS_CheckReg_CLMH2 


SELECT * FROM dbo.SSRS_CheckReg_CJP2
SELECT * FROM dbo.SSRS_CheckReg_GRP2
SELECT * FROM dbo.SSRS_CheckReg_Patient2
SELECT * FROM dbo.SSRS_CheckReg_CLMH2


DECLARE @AllConnections TABLE(
    SPID INT,
    Status VARCHAR(MAX),
    LOGIN VARCHAR(MAX),
    HostName VARCHAR(MAX),
    BlkBy VARCHAR(MAX),
    DBName VARCHAR(MAX),
    Command VARCHAR(MAX),
    CPUTime INT,
    DiskIO INT,
    LastBatch VARCHAR(MAX),
    ProgramName VARCHAR(MAX),
    SPID_1 INT,
    REQUESTID INT
)

INSERT INTO @AllConnections EXEC sp_who2

SELECT * FROM @AllConnections WHERE DBName = 'ODS'

ALTER DATABASE ODS SET SINGLE_USER WITH ROLLBACK immediate
ALTER DATABASE ODS SET ENABLE_BROKER
ALTER DATABASE ODS SET MULTI_USER
