
USE [DAR_Claims_Staging]
GO
/****** Object:  StoredProcedure [stage].[spCM_UAS_MLTC_FileLoad_Step3]    Script Date: 8/26/2015 4:05:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Created by Alex Yoo

	Date			Comment
	2015-07-15		1.0

	This sproc parses raw xml nodes to sql cases and measures tables.
	
	**** Parameters ****
	None
*/
CREATE PROC [stage].[spCM_UAS_MLTC_FileLoad_Step3]

AS
/*
TRUNCATE TABLE DAR_CM.prod.UAS_MLTC_Cases
TRUNCATE TABLE DAR_CM.prod.UAS_MLTC_Measures
*/
/*declare variables*/
DECLARE @XML XML, @iDoc int, @FileID int, @MaxID int, @i int;
DECLARE @temp TABLE (ID int, FileID int); 

/*temporarily store fileid of all files not processed with left join is null*/
INSERT INTO @temp(ID, FileID)
SELECT ROW_NUMBER() OVER (ORDER BY fd.FileID) ID
	 , fd.FileID
FROM [prod].[UAS_MLTC_FileData] fd
LEFT JOIN DAR_CM.prod.UAS_MLTC_Cases cc
	ON fd.FileID = cc.FileID
WHERE fd.Cases > 0
	AND cc.CaseID IS NULL

/*store max fileid to get while loop terminator*/
SELECT @MaxID = MAX(ID), @i = 1
FROM @temp

/*loop over all unprocessed files*/
IF (@MaxID IS NOT NULL)
	BEGIN
		WHILE @i <= @MaxID
			BEGIN
				/* load FileID */
				SELECT @FileID = FileID
				FROM @temp
				WHERE ID = @i;
				
				/* load XML to variable for openxml query*/
				SELECT @XML = XML_Data
				FROM DAR_Claims_Staging.prod.UAS_MLTC_FileData
				WHERE FileID = @FileID;

				EXEC sp_xml_preparedocument @iDoc OUTPUT, @XML;

				/* delete existing cases for FileID */
				DELETE FROM DAR_CM.prod.UAS_MLTC_Cases
				WHERE FileID = @FilEID

				/* insert new cases into prod.UAS_MLTS_Cases */
				INSERT INTO DAR_CM.prod.UAS_MLTC_Cases(
					FileID
					, CaseID
					, AssessmentDate
					, functionalDate
					, BComments
					, physOrder
					, physName
					, physNumber
					, ppEnrollDate
					, ppEnrollPlan
					, ppProvider
					, ppAssessingOrgName
					, MemberID
					, ts)
				SELECT 
					@FileID FileID
					, CaseID
					, AssessmentDate
					, functionalDate
					, BComments
					, physOrder
					, physName
					, physNumber
					, ppEnrollDate
					, ppEnrollPlan
					, ppProvider
					, ppAssessingOrgName
					, MemberID
					, GETDATE() ts
				FROM OPENXML(@iDoc, '//Assessment',0)
				WITH (	  CaseID				INT				'../@ID',      
						   AssessmentDate		DATE			'assessmentDate',
						   functionalDate		DATE			'CommunityHealth/ChaSupplement/functionalDate',
						   BComments			VARCHAR(500)	'CommunityHealth/BComments',

						   MemberID				VARCHAR(20)		'../medicaidNumber1',
						   physOrder			smallint		'CommunityHealth/physOrder',
						   physName				varchar(255)	'CommunityHealth/physName',
						   physNumber			int				'CommunityHealth/physNumber',
						   ppEnrollDate			date			'../ProgramPlan/ppEnrollDate',
						   ppEnrollPlan			smallint		'../ProgramPlan/ppEnrollPlan',
						   ppProvider			varchar(255)	'../ProgramPlan/ppProvider',
						   ppAssessingOrgName	varchar(255)	'../ProgramPlan/ppAssessingOrgName')

				
				/* Update YYYYMMDD, AssessmentDate_BOY, Age_Month and Age_Year on UAS_MLTC_Cases */
				UPDATE cc
				SET YYYYMMDD = CONVERT(VARCHAR(8), AssessmentDate, 112)
					,AssessmentDate_BOY = DATEADD(YEAR, DATEDIFF(YEAR, 0, AssessmentDate), 0)
					,Age_Month = DATEDIFF(MONTH, convert(smalldatetime, right(uu.dob, 4) + left(uu.dob, 4), 112), DATEADD(YEAR, DATEDIFF(YEAR, 0, AssessmentDate), 0))
					,Age_Year = DATEDIFF(YEAR, convert(smalldatetime, right(uu.dob, 4) + left(uu.dob, 4), 112), DATEADD(YEAR, DATEDIFF(YEAR, 0, AssessmentDate), 0))
				FROM DAR_CM.prod.UAS_MLTC_Cases AS cc
				LEFT JOIN (
					select distinct [recipient id], dob
					from DAR_CM.prod.UAS_Roster
						 ) AS uu
					ON cc.MemberID = uu.[recipient id]
				WHERE cc.FileID = @FileID

				;with DirtyData as (
					select
						row_number() over (order by NFLOC) as ID
						,NFLOC
						,rtrim(case
									when charindex('NF-LOC', bcomments) > 0 then substring(bcomments, charindex('NF-LOC', bcomments), 11)
									when charindex('NFLOC', bcomments) > 0 then substring(bcomments, charindex('NFLOC', bcomments), 10)
								end) as NFLOC2
					FROM DAR_CM.prod.UAS_MLTC_Cases AS cc
					where (charindex('NF-LOC', bcomments) > 0 OR charindex('NFLOC', bcomments) > 0)
				)
				, CleanData as (
					select xx.ID, xx.Num, xx.Chr
					from support.tally as tt
					cross apply (
						SELECT dd.id
							,tt.Num
							,substring(dd.NFLOC2, tt.Num, 1) as Chr
						from DirtyData as dd
						where tt.Num <= len(dd.NFLOC2)
					) as xx
					left join support.tallychar as cc
						on xx.Chr = cc.Chr
					where patindex('%[0-9]%', xx.Chr) > 0
				)
				update dd
				set NFLOC = cast((
						select rtrim(dd.Chr)
						from CleanData as dd
						where id = cc.id
						order by dd.Num
						for xml path('')
					) as int)
				from CleanData as cc
				join DirtyData as dd
					on cc.id = dd.id
						
				/* Measures with 5 unions*/
				DELETE FROM DAR_CM.prod.UAS_MLTC_Measures
				WHERE FileID = @FilEID

				INSERT INTO DAR_CM.prod.UAS_MLTC_Measures(FileID, CaseID, Measure, Value, Source, ts)
				SELECT @FileID FileID, CaseID, Measure, isnull(Value,-1), 'Assessment' Source, GETDATE() ts
				FROM (
						SELECT *
						FROM OPENXML(@iDoc, '//Assessment',0)
						WITH (	CaseID							INT				'../@ID',
								levelOfCareScore				TINYINT			'levelOfCareScore')
					 ) source
				UNPIVOT
					(Value FOR Measure IN ([levelOfCareScore])) unpvt
					
				UNION

				SELECT @FileID FileID, CaseID, Measure, isnull(Value,-1), 'Case' Source, GETDATE() ts
				FROM (
						SELECT CaseID, [Gender],[sexualOrientation],[raceAsian],[raceBlack],[raceIslander],[raceNative],[raceWhite]
						FROM OPENXML(@iDoc, '//Case',0)
						WITH (	CaseID							INT				'@ID',
								Gender							TINYINT			'Gender',
								sexualOrientation				TINYINT			'sexualOrientation',
								raceAsian						TINYINT			'raceAsian',
								raceBlack						TINYINT			'raceBlack',
								raceIslander					TINYINT			'raceIslander',
								raceNative						TINYINT			'raceNative',
								raceWhite						TINYINT			'raceWhite')
					 ) source
				UNPIVOT
					(Value FOR Measure IN ([Gender],[sexualOrientation],[raceAsian],[raceBlack],[raceIslander],[raceNative]
					,[raceWhite])) unpvt

				UNION

				SELECT @FileID FileID, CaseID, Measure, isnull(Value,-1), 'CommunityHealth' Source, GETDATE() ts
				FROM (	
						SELECT *
						FROM   OPENXML(@iDoc, '//CommunityHealth', 0) 
						WITH (	CaseID						 INT			'../../@ID',
								adlbathing                   TINYINT		'adlBathing', 
								adldressupper                TINYINT		'adlDressUpper', 
								adllocomotion                TINYINT		'adlLocomotion', 
								adltoilettransfer            TINYINT		'adlToiletTransfer', 
								bladdercontinence            TINYINT		'bladderContinence', 
								cardiacfailure               TINYINT		'cardiacFailure', 
								cardiacheartdisease          TINYINT		'cardiacHeartDisease', 
								cardiacpulmonary             TINYINT		'cardiacPulmonary', 
								cognitiveskills              TINYINT		'cognitiveSkills', 
								dyspnea                      TINYINT		'dyspnea',
								falls						 TINYINT		'falls',
								fallsmedical                 TINYINT		'fallsMedical', 
								hearing                      TINYINT		'hearing', 
								iadlcapacitymeds             TINYINT		'iadlCapacityMeds', 
								iadlperformancemeds          TINYINT		'iadlPerformanceMeds', 
								lifestylealcohol             TINYINT		'lifestyleAlcohol', 
								lifestylechewstobacco        TINYINT		'lifestyleChewsTobacco', 
								lifestylesmokes              TINYINT		'lifestyleSmokes',  
								lonely                       TINYINT		'lonely', 
								neurologicalalzheimers       TINYINT		'neurologicalAlzheimers', 
								neurologicaldementia         TINYINT		'neurologicalDementia',  
								nhendoflife                  TINYINT		'nhEndOfLife',
								otherdiabetes                TINYINT		'otherDiabetes', 
								painfrequency                TINYINT		'painFrequency', 
								painintensity                TINYINT		'painIntensity', 
								psychiatricdepression        TINYINT		'psychiatricDepression', 
								txcolonoscopy                TINYINT		'txColonoscopy', 
								txemergency                  TINYINT		'txEmergency', 
								txeye                        TINYINT		'txEye', 
								txhearing                    TINYINT		'txHearing', 
								txinfluenza                  TINYINT		'txInfluenza', 
								txinpatient                  TINYINT		'txInpatient',
								txmammogram                  TINYINT		'txMammogram',
								txpneumovax					 TINYINT		'txPneumovax',  
								vision                       TINYINT		'vision',
								livingArrangement			 TINYINT	    'livingArrangement',		-- added later
								withdrawal				     TINYINT	    'withdrawal',
								behaviorWandering		     TINYINT	    'behaviorWandering',
								behaviorVerbal			     TINYINT	    'behaviorVerbal',
								behaviorPhysical		     TINYINT	    'behaviorPhysical',
								behaviorDisruptive		     TINYINT	    'behaviorDisruptive',
								behaviorSexual			     TINYINT	    'behaviorSexual',
								behaviorResists				 TINYINT	    'behaviorResists',
								moodAnxious					 TINYINT	    'moodAnxious',
								moodSad						 TINYINT	    'moodSad',
								socialChangeActivities		 TINYINT	    'socialChangeActivities',
								timeAlone					 TINYINT	    'timeAlone',
								lifeStressors				 TINYINT	    'lifeStressors',
								adlDressLower				 TINYINT	    'adlDressLower',
								adlToiletUse				 TINYINT	    'adlToiletUse',
								adlEating					 TINYINT	    'adlEating',
								bowelContinence				 TINYINT	    'bowelContinence',
								txDental					 TINYINT	    'txDental',					--added 20150309
								iadlPerformanceStairs		TINYINT			'iadlPerformanceStairs',
								iadlCapacityStairs			TINYINT			'iadlCapacityStairs',
								locomotionIndoors			TINYINT			'locomotionIndoors',
								nutritionalIntake			TINYINT			'nutritionalIntake',
								memoryRecallShort			TINYINT			'memoryRecallShort',
								memoryRecallProcedural		TINYINT			'memoryRecallProcedural',
								selfUnderstood				TINYINT			'selfUnderstood',
								assessmentReason			TINYINT			'assessmentReason')			--added 20150410
						) source
				UNPIVOT
					(Value FOR Measure IN ([adlbathing],[adldressupper],[adllocomotion],[adltoilettransfer],[bladdercontinence],[cardiacfailure],[cardiacheartdisease]
										  ,[cardiacpulmonary],[cognitiveskills],[dyspnea],[falls],[fallsmedical],[hearing],[iadlcapacitymeds],[iadlperformancemeds],[lifestylealcohol]
										  ,[lifestylechewstobacco],[lifestylesmokes],[lonely],[neurologicalalzheimers],[neurologicaldementia],[nhendoflife],[otherdiabetes]
										  ,[painfrequency],[painintensity],[psychiatricdepression],[txcolonoscopy],[txemergency],[txeye],[txhearing],[txinfluenza],[txinpatient]
										  ,[txmammogram],[txpneumovax],[vision]
										  ,[livingArrangement],[withdrawal],[behaviorWandering],[behaviorVerbal],[behaviorPhysical]		-- added later
										  ,[behaviorDisruptive],[behaviorSexual],[behaviorResists],[moodAnxious],[moodSad]
										  ,[socialChangeActivities],[timeAlone],[lifeStressors],[adlDressLower],[adlToiletUse]
										  ,[adlEating],[bowelContinence],[txDental]
										  ,[iadlPerformanceStairs],[iadlCapacityStairs],[locomotionIndoors],[nutritionalIntake]
										  ,[memoryRecallShort],[memoryRecallProcedural],[selfUnderstood], [assessmentReason])) unpvt 

				UNION

				SELECT @FileID FileID, CaseID, Measure, isnull(Value,-1), 'ChaSupplement' Source, GETDATE() ts
				FROM (
						SELECT *
						FROM OPENXML(@iDoc,'//ChaSupplement',0)
						WITH (	CaseID							INT			'../../../@ID',
								advancedDirectives				TINYINT		'advancedDirectives',
								drugAdherent					TINYINT		'drugAdherent',
								txDialysis						TINYINT		'txDialysis',
								urinaryDevice					TINYINT		'urinaryDevice')
					 ) source
				UNPIVOT
					(Value FOR Measure IN ([advancedDirectives],[drugAdherent],[txDialysis],[urinaryDevice])) unpvt
				
				UNION
								
				SELECT @FileID FileID, CaseID, name AS Measure, isnull(CAST(value AS INT),-1) AS Value, 'Scale' Source, GETDATE() ts		-- added later
				FROM OPENXML(@iDoc,'//Scale',0)
				WITH (	CaseID									INT					'../../@ID',
						name									VARCHAR(100)		'name',
						value									NUMERIC(6,2)		'value')
				WHERE name IN ('Cognitive Performance Scale','Cognitive Performance Scale 2'
					,'Depression Rating Scale', 'IADL Capacity Scale', 'ADL Hierarchy Scale')
				
				UNION
				-- + '-' + triggeredtext 
				SELECT @FileID FileID, CaseID, name AS Measure, isnull(triggered,-1) as Value, 'Cap' Source, GETDATE() ts
				FROM OPENXML(@iDoc, '//Cap', 0) 
				WITH (
					 CaseID										INT               '../../@ID'
					 ,name										VARCHAR(100)      'name'
					 ,triggeredText								VARCHAR(250)      'triggeredText'
					 ,triggered									INT               'triggered')
			
				ORDER BY CaseID, Source, Measure;

				EXEC sp_xml_removedocument @iDoc;

				SET @i = @i + 1;
			END
	END;

/* Add missing Measures to UAS_MLTC_Measure_Type */
WITH measures AS
(
SELECT [Measure], Source
FROM DAR_CM.[prod].[UAS_MLTC_Measures]
GROUP BY [Measure], Source
)

INSERT INTO DAR_CM.prod.UAS_MLTC_Measure_Types(Measure, Source)
SELECT aa.Measure, aa.Source
FROM measures aa
LEFT JOIN DAR_CM.prod.UAS_MLTC_Measure_Types bb
	ON aa.Measure = bb.Measure
WHERE bb.Measure IS NULL
ORDER BY aa.Measure;
GO
