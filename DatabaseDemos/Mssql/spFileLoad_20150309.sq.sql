USE [DAR_Claims_Staging]
GO
/****** Object:  StoredProcedure [stage].[spCM_UAS_MLTC_FileLoad_Step3]    Script Date: 3/9/2015 12:18:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [stage].[spCM_UAS_MLTC_FileLoad_Step3]

AS

/*
TRUNCATE TABLE prod.UAS_MLTC_Cases
TRUNCATE TABLE prod.UAS_MLTC_Measures
*/

DECLARE @XML XML, @iDoc int, @FileID int, @MaxID int, @i int;
DECLARE @temp TABLE (ID int, FileID int); 

INSERT INTO @temp(ID, FileID)
SELECT ROW_NUMBER() OVER (ORDER BY fd.FileID) ID
	 , fd.FileID
FROM [prod].[UAS_MLTC_FileData] fd
LEFT JOIN prod.UAS_MLTC_Cases cc
	ON fd.FileID = cc.FileID
WHERE fd.Cases > 0
	AND cc.CaseID IS NULL

SELECT @MaxID = MAX(ID), @i = 1
FROM @temp

IF (@MaxID IS NOT NULL)
	BEGIN
		WHILE @i <= @MaxID
			BEGIN
				/* load FileID */
				SELECT @FileID = FileID
				FROM @temp
				WHERE ID = @i;
				
				/* load XML to variable */
				SELECT @XML = XML_Data
				FROM DAR_Claims_Staging.prod.UAS_MLTC_FileData
				WHERE FileID = @FileID;

				EXEC sp_xml_preparedocument @iDoc OUTPUT, @XML;

				/* delete existing cases for FileID */
				DELETE FROM prod.UAS_MLTC_Cases
				WHERE FileID = @FilEID

				/* insert new cases into prod.UAS_MLTS_Cases */
				INSERT INTO prod.UAS_MLTC_Cases(FileID, CaseID, AssessmentDate, functionalDate, BComments, MemberID, ts)
				SELECT @FileID FileID, CaseID, AssessmentDate, functionalDate, BComments, MemberID, GETDATE() ts
				FROM OPENXML(@iDoc, '//Assessment',0)
				WITH (	  CaseID                                  INT                     '../@ID',      
						   AssessmentDate                         DATE				 'assessmentDate',
						   functionalDate                         DATE				 'CommunityHealth/ChaSupplement/functionalDate',
						   BComments                              VARCHAR(500)			 'CommunityHealth/BComments',
						   MemberID                               VARCHAR(20)			 '../medicaidNumber1')

						
				
				/* Update YYYYMMDD, AssessmentDate_BOY, Age_Month and Age_Year on UAS_MLTC_Cases */
				UPDATE cc
				SET YYYYMMDD = CONVERT(VARCHAR(8), AssessmentDate, 112),
					AssessmentDate_BOY = DATEADD(YEAR, DATEDIFF(YEAR, 0, AssessmentDate), 0),
					Age_Month = DATEDIFF(MONTH, uu.dob, DATEADD(YEAR, DATEDIFF(YEAR, 0, AssessmentDate), 0)),
					Age_Year = DATEDIFF(YEAR, uu.dob, DATEADD(YEAR, DATEDIFF(YEAR, 0, AssessmentDate), 0))
				FROM prod.UAS_MLTC_Cases AS cc
				LEFT JOIN prod.UAS_Roster_Unique AS uu
						 ON cc.MemberID = uu.MemberID
				WHERE cc.FileID = @FileID

						
				/* Measures */
				DELETE FROM prod.UAS_MLTC_Measures
				WHERE FileID = @FilEID

				INSERT INTO prod.UAS_MLTC_Measures(FileID, CaseID, Measure, Value, Source, ts)
				SELECT @FileID FileID, CaseID, Measure, Value, 'Assessment' Source, GETDATE() ts
				FROM (
						SELECT *
						FROM OPENXML(@iDoc, '//Assessment',0)
						WITH (	CaseID							INT				'../@ID',
								levelOfCareScore				TINYINT			'levelOfCareScore')
					 ) source
				UNPIVOT
					(Value FOR Measure IN ([levelOfCareScore])) unpvt
					
				UNION

				SELECT @FileID FileID, CaseID, Measure, Value, 'Case' Source, GETDATE() ts
				FROM (
						SELECT CaseID, [Gender],[raceAsian],[raceBlack],[raceIslander],[raceNative],[raceWhite]
						FROM OPENXML(@iDoc, '//Case',0)
						WITH (	CaseID							INT				'@ID',
								Gender							TINYINT			'Gender',
								raceAsian						TINYINT			'raceAsian',
								raceBlack						TINYINT			'raceBlack',
								raceIslander					TINYINT			'raceIslander',
								raceNative						TINYINT			'raceNative',
								raceWhite						TINYINT			'raceWhite')
					 ) source
				UNPIVOT
					(Value FOR Measure IN ([Gender],[raceAsian],[raceBlack],[raceIslander],[raceNative],[raceWhite])) unpvt

				UNION

				SELECT @FileID FileID, CaseID, Measure, Value, 'CommunityHealth' Source, GETDATE() ts
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
								nutritionalIntake			TINYINT			'nutritionalIntake')
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
										  ,[iadlPerformanceStairs],[iadlCapacityStairs],[locomotionIndoors],[nutritionalIntake])) unpvt 

				UNION

				SELECT @FileID FileID, CaseID, Measure, Value, 'ChaSupplement' Source, GETDATE() ts
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
								
				SELECT @FileID FileID, CaseID, name AS Measure, CAST(value AS INT) AS Value, 'Scale' Source, GETDATE() ts		-- added later
				FROM OPENXML(@iDoc,'//Scale',0)
				WITH (	CaseID									INT					'../../@ID',
						name									VARCHAR(100)		'name',
						value									NUMERIC(6,2)		'value')
				WHERE name IN ('Cognitive Performance Scale','Cognitive Performance Scale 2','Depression Rating Scale')
				
				UNION
				
				SELECT @FileID FileID, CaseID, name + '-' + triggeredtext AS Measure, triggered as Value, 'Cap' Source, GETDATE() ts
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
FROM [DAR_Claims_Staging].[prod].[UAS_MLTC_Measures]
GROUP BY [Measure], Source
)

INSERT INTO prod.UAS_MLTC_Measure_Types(Measure, Source)
SELECT aa.Measure, aa.Source
FROM measures aa
LEFT JOIN prod.UAS_MLTC_Measure_Types bb
	ON aa.Measure = bb.Measure
WHERE bb.Measure IS NULL
ORDER BY aa.Measure;