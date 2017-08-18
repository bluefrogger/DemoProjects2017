/*
https://social.msdn.microsoft.com/Forums/sqlserver/en-US/2cbb0ea1-d061-4f5b-ba65-b0e152cd79ad/while-loop-with-waitfor-delay?forum=transactsql
SELECT * INTO dbo.SSRS_CheckReg_Queue FROM sql2.ODS.dbo.SSRS_CheckReg_Queue
SELECT * INTO dbo.SSRS_CheckReg_CJP FROM sql2.ODS.dbo.SSRS_CheckReg_CJP
SELECT * INTO dbo.SSRS_CheckReg_GRP FROM sql2.ODS.dbo.SSRS_CheckReg_GRP
SELECT * INTO dbo.SSRS_CheckReg_Patient FROM sql2.ODS.dbo.SSRS_CheckReg_Patient
SELECT * FROM dbo.SSRS_CheckReg_CJP WHERE punbr = '002' AND grnbr = '285';
SELECT * FROM dbo.SSRS_CheckReg_Queue where runid = 'F7D3DA30-FA19-4C78-A02D-39393D42993C';
*/
USE ODS
GO

SELECT  CJP.FISSDATE AS ChkIssueDtMMDDYYYY
        ,RTRIM(LTRIM(CJP.CHECKNO)) AS ChkNo
        ,CJP.CHECKTYPE AS CheckType
        ,CJP.TYPE AS ChkType
        ,GRP.NAME AS GrpName
        ,CJP.PUNBR AS GrpPolUnd
        ,CJP.GRNBR AS GrpNo
        ,CJP.DEPT AS EmpDept
        ,CJP.FCINCDT AS ClmIncDtMMDDYYYY
        ,CJP.POLICY AS ClmType
        ,CJP.CLAIM AS ClmNo
        ,CJP.ESSN AS EmpSSN
        ,CJP.SEQ AS PatSeq
        ,PATIENT.LNAME AS InsLname
        ,PATIENT.FTNAME AS InsFname
        ,PATIENT.MINIT AS InsMI
        ,PATIENT_1.LNAME AS PatLname
        ,PATIENT_1.FTNAME AS PatFname
        ,PATIENT_1.MINIT AS PatMI
        ,CJP.PAYEE AS PayeeTaxID
        ,CJP.PNAME AS PayeeName
        ,CJP.PAY AS PmtAmt
FROM    dbo.SSRS_CheckReg_Queue CRQ
INNER JOIN SSRS_CheckReg_CJP AS CJP ON CRQ.RunID = CJP.RunID
LEFT OUTER JOIN SSRS_CheckReg_GRP AS GRP ON CJP.PUNBR = GRP.PUNBR
                                    AND CJP.GRNBR = GRP.GRNBR
                                    AND CJP.RunID = GRP.RunID
LEFT OUTER JOIN SSRS_CheckReg_Patient AS PATIENT ON CJP.ESSN = PATIENT.ESSN
                                    AND CJP.GRNBR = PATIENT.GRNBR
                                    AND CJP.PUNBR = PATIENT.PUNBR
                                    AND PATIENT.SEQ = '00'
                                    AND CJP.RunID = PATIENT.RunID
LEFT OUTER JOIN SSRS_CheckReg_Patient AS PATIENT_1 ON CJP.SEQ = PATIENT_1.SEQ
                                    AND CJP.ESSN = PATIENT_1.ESSN
                                    AND CJP.GRNBR = PATIENT_1.GRNBR
                                    AND CJP.PUNBR = PATIENT_1.PUNBR
                                    AND CJP.RunID = PATIENT_1.RunID
--WHERE     CJP.FISSDATE = @FISSDATE  
WHERE   CRQ.RunID = @RunID
        AND CRQ.PUNBR = @PUNBR
        AND CRQ.GRNBR = @GRNBR  
--AND          PATIENT.SEQ = '00' 
        AND CJP.TYPE IN ( @ChkType01, @ChkType02,
                            @ChkType03, @ChkType04 )
ORDER BY CJP.FISSDATE
        ,CJP.CHECKNO;
GO

Alter PROC [dbo].[SSRS_CheckRegisterForApprovals2] (
	@PUNBR NVARCHAR(3)
    , @GRNBR NVARCHAR(3)
    , @StartDate DATETIME
    , @EndDate DATETIME
    , @ChkType01 CHAR(1) = ''
    , @ChkType02 CHAR(1) = ''
    , @ChkType03 CHAR(1) = ''
    , @ChkType04 CHAR(1) = ''
) AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @RunID UNIQUEIDENTIFIER = NEWID();
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

	DECLARE @TimeOut int = 320;
	DECLARE @StartTime DATETIME = GETDATE();

	WHILE (1 = 1)
	BEGIN
		WAITFOR DELAY '00:00:00.400';
		IF EXISTS (SELECT * FROM dbo.SSRS_CheckReg_CJP WHERE RunID = @RunID)
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
			FROM  SSRS_CheckReg_CJP2 AS CJP
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
END
GO
