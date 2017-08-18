/*
DECLARE @PUNBR nvarchar(3)
DECLARE @GRNBR nvarchar(3)
DECLARE @StartDate DATETIME
DECLARE @EndDate DATETIME
DECLARE @ChkType01  char(1) = '1'
DECLARE @ChkType02  char(1) = '0'
DECLARE @ChkType03  char(1) = '3'
DECLARE @ChkType04  char(1) = '0'

SET @PUNBR = '002'
SET @GRNBR = '225'
SET @StartDate = '09/23/2014' --'20140915'
SET @EndDate = '09/23/2014'
*/
-- AUTHOR: Keith Mitchell
-- Purpose: Check Register for delivery to BC Online for Approval
-- Date Created: 
-- Date Modified: 
-- Notes: 

USE [Development];
GO
/****** Object:  StoredProcedure [dbo].[SSRS_CheckRegisterForApprovals] Script Date: 6/29/2016 3:47:59 PM ******/

CREATE  PROC [dbo].[SSRS_CheckRegisterForApprovals] --dbo.PcrInitiatorActivate
    (
     @PUNBR NVARCHAR(3)
    ,@GRNBR NVARCHAR(3)
    ,@StartDate DATETIME
    ,@EndDate DATETIME
    ,@ChkType01 CHAR(1) = ''
    ,@ChkType02 CHAR(1) = ''
    ,@ChkType03 CHAR(1) = ''
    ,@ChkType04 CHAR(1) = ''
    )
AS
BEGIN
    DECLARE @DEBUGSW BIT = 0;

    DECLARE @UndGrpID INT;
    DECLARE @PreRegID INT;
    DECLARE @SchedID INT;
    DECLARE @DateTimeStamp DATETIME;

    DECLARE @ESSN NVARCHAR(9);
    DECLARE @SEQ NVARCHAR(2);

    DECLARE @ProvKey NVARCHAR(8);
    DECLARE @PROCCode NVARCHAR(6);
    DECLARE @PROCDesc NVARCHAR(40);
    DECLARE @CLAIM NVARCHAR(11);
    DECLARE @DIAGCode NVARCHAR(8);

    DECLARE @FISSDATE DATETIME;
    DECLARE @CurrentDate DATETIME;
    DECLARE @ISSDATE NVARCHAR(8);

    DECLARE @TableOfDates TABLE ( DateValue DATETIME );

/***************************************************************************************************
									Load Temp Tables
****************************************************************************************************/
    DECLARE @RunID NVARCHAR(50) = CAST(NEWID() AS NVARCHAR(50));

    INSERT  INTO dbo.SSRS_CheckReg_Queue
            (PUNBR
            ,GRNBR
            ,BegPaidDate
            ,EndPaidDate
            ,DateRequested
            ,RunID
            ,InProcess
            ,Processed
		    )
    VALUES  (@PUNBR
            ,@GRNBR
            ,CONVERT(CHAR(8), @StartDate, 112)
            ,CONVERT(CHAR(8), @EndDate, 112)
            ,GETDATE()
            ,@RunID
            ,0
            ,0
            ); 
	
    DECLARE @IsProcessed BIT = 0;
    DECLARE @LoopTimeLimit INT = 600;
    DECLARE @LoopStartTime DATETIME; 
    DECLARE @CurrDiff INT;
    DECLARE @LastDiff INT;

    SET @IsProcessed = 0;
    SET @LoopStartTime = GETDATE();

    SET @LastDiff = 1;
		
	-- create xml messages from parameters and insert into dbo.PcrLog

	INSERT dbo.PcrLog (message_body, StateDesc)
	SELECT 
	XmlOut = 
	(
		SELECT 
			XmlRw.*
		FROM dbo.SSRS_CheckReg_Queue XmlRw
		WHERE xmlRw.SSRSCheckRegQueueID = ssrs.SSRSCheckRegQueueID
		FOR XML PATH ('')
	)
	, 'InitializeSB'
	FROM dbo.SSRS_CheckReg_Queue ssrs

	-- get the message body
	DECLARE @MessageBodyIn xml = (SELECT TOP (1) message_body FROM dbo.PcrLog ORDER BY ts desc)

	-- send the message to the target queue
	EXEC dbo.PcrMessage 
		@FromService = 'PcrInitiatorService'
		, @ToService = 'PcrTargetService'
		, @Contract = 'PcrContract'
		, @MessageType = 'PcrRequest'
		,@MessageBody = 

	-- receive messages from the queue
	DECLARE @message_body XML;
	DECLARE @message_type_name sysname;
	DECLARE @conversation_handle UNIQUEIDENTIFIER;

	WHILE (1 = 1)
	BEGIN
		BEGIN TRAN
			WAITFOR(
				RECEIVE TOP (1)
				@conversation_handle = conversation_handle,
				@message_body = CAST(message_body AS XML),
				@message_type_name = message_type_name
			FROM PcrInitiatorQueue
			), TIMEOUT 5000;

			IF (@@rowcount = 0)
			BEGIN
				ROLLBACK TRAN;
				BREAK;
			END

			IF @message_type_name = 'PcrResponse'
			BEGIN
				--end the conversation after receiving the response
				END CONVERSATION @conversation_handle;

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
   
            SET @CurrDiff = DATEDIFF(SECOND, @LoopStartTime, GETDATE());
            IF @CurrDiff <> @LastDiff
                PRINT CAST(DATEDIFF(SECOND, @LoopStartTime, GETDATE()) AS NVARCHAR(50));
            SET @LastDiff = @CurrDiff;
        END
		ELSE IF @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
		BEGIN
		   END CONVERSATION @conversation_handle;
		END
	END
END