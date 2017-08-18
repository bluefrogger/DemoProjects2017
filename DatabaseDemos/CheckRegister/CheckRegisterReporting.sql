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

USE ODS;
GO
/****** Object:  StoredProcedure [dbo].[SSRS_CheckRegisterForApprovals] Script Date: 6/29/2016 3:47:59 PM ******/

ALTER PROC [dbo].[SSRS_CheckRegisterForApprovals]
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
		
		-- *************  Fire off Agent/SSIS Job
		--EXEC msdb.dbo.sp_start_job N'BC_jb_SSRS_ProcessCheckRegQueue' 
	
    DECLARE @IsProcessed BIT = 0;
    DECLARE @LoopTimeLimit INT = 600;
    DECLARE @LoopStartTime DATETIME; 
    DECLARE @CurrDiff INT;
    DECLARE @LastDiff INT;

    SET @IsProcessed = 0;
    SET @LoopStartTime = GETDATE();

    SET @LastDiff = 1;
		
		-- This WHILE loop is designed to wait for the Agent job to finish or timeout after 5 minutes
		--		, whichever comes first
	
    WHILE @IsProcessed = 0
        AND DATEDIFF(SECOND, @LoopStartTime, GETDATE()) < @LoopTimeLimit
        BEGIN -- *********************Loop**************************
            SELECT  @IsProcessed = Processed
            FROM    dbo.SSRS_CheckReg_Queue
            WHERE   RunID = @RunID;
			
            IF @IsProcessed = 1
                BEGIN -- ******************IsProcessed ***********************

                    IF @DEBUGSW = 1
                        SELECT  *
                        FROM    SSRS_CheckReg_Patient;
				
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
					
                END; -- ******************IsProcessed ***********************
			
            SET @CurrDiff = DATEDIFF(SECOND, @LoopStartTime, GETDATE());
            IF @CurrDiff <> @LastDiff
                PRINT CAST(DATEDIFF(SECOND, @LoopStartTime, GETDATE()) AS NVARCHAR(50));
            SET @LastDiff = @CurrDiff;
        END; -- *********************Loop**************************
GO
