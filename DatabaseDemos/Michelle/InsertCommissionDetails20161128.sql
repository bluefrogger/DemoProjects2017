USE [KemperGroupDev]
GO
/****** Object:  StoredProcedure [dbo].[KG_Agent_Commission_InsertCommissionDetails]    Script Date: 11/28/2016 9:14:34 AM ******/
EXEC [dbo].[KG_Agent_Commission_InsertCommissionDetails] @WorkflowInstanceID = 491494, @IsDeleted = 1

SELECT  FROM dbo.CommissionSetupDetails AS csd WHERE workflowinstanceid = 491494
SELECT * FROM #bak WHERE workflowinstanceid = 491494


SELECT  csd.WorkflowInstanceID , csdf.WorkflowInstanceID 
	,csd.CommissionSetupID , csdf.CommissionSetupID 
	,csd.DirectUplineProducerID , csdf.DirectUplineProducerID
	,csd.Source_ProducerID , csdf.Source_ProducerID
	,csd.GroupProductID , csdf.GroupProductID
	,csd.CommissionScheduleDetailID1stYearMatch , csdf.CommissionScheduleDetailID1stYearMatch
FROM dbo.CommissionSetupDetails AS csd
left JOIN #bak AS csdf
	ON csd.WorkflowInstanceID = csdf.WorkflowInstanceID
		AND csd.CommissionSetupID = csdf.CommissionSetupID 
		AND csd.DirectUplineProducerID = csdf.DirectUplineProducerID
		AND csd.Source_ProducerID = csdf.Source_ProducerID
		AND csd.GroupProductID = csdf.GroupProductID
		AND csd.CommissionScheduleDetailID1stYearMatch = csdf.CommissionScheduleDetailID1stYearMatch
WHERE csd.WorkflowInstanceID = 491494 AND csdf.WorkflowInstanceID IS NULL

SELECT * FROM #bak WHERE source_producerid = 35550 AND WorkflowInstanceID = 491494 AND groupproductid = 345165

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[KG_Agent_Commission_InsertCommissionDetails] (
	@WorkflowInstanceID INT = NULL	
	,@CommissionSetupDetailNotes NVARCHAR(MAX) = NULL
	,@IsDeleted BIT = NULL
	,@CommissionScheduleDetailID_Override INT = NULL
)
AS
BEGIN
	IF OBJECT_ID('tempdb..#CommissionSetupDetails') IS NOT NULL
		DROP TABLE #CommissionSetupDetails;
			
	SELECT DISTINCT
		cs.CommissionSetupID
		,cs.CommissionScheduleTypeID
		,cs.CommissionSetupNotes
		,cs.OverrideDefaultScheduleLevelID
		,wcps.GroupProductID	
		,kp.ProducerID
		,kp.CarrierID
		,cp.CarrierProductID
		,cp.CarrierProductCode
		,cs.WorkflowInstanceID
		,rcat.CommissionAgentType
		,cs.WritingNumber
		,cs.SplitPercentage
	INTO #CommissionSetupDetails
	FROM dbo.CommissionSetup AS cs
	INNER JOIN dbo.Wf_CommissionProductSelections AS wcps
		ON WCPS.WorkflowinstanceID = CS.WorkflowInstanceID
	INNER JOIN dbo.Kemper_Producers AS kp
		ON kp.WritingNumber = cs.WritingNumber
	INNER JOIN dbo.EntityExternalIdents AS eei
		ON eei.ExternalIdentifier = kp.WritingNumber AND eei.ExternalIdentTypeID = 1601
	INNER JOIN dbo.EntityExternalIdents AS eei2
		ON eei2.ExternalIdentifier = kp.ProducerID AND eei2.ExternalIdentTypeID = 1600
	INNER JOIN dbo.CarrierProducts AS cp
		ON CP.CarrierProductID = wcps.CarrierProductID
	INNER JOIN dbo.rf_CommissionAgentTypes AS rcat
		ON rcat.CommissionAgentTypeID = cs.CommissionAgentTypeID

	IF OBJECT_ID('tempdb..#CommissionScheduleDetails') IS NOT NULL
		DROP TABLE #CommissionScheduleDetails;

	--  dbo.CommissionScheduleDetailAges has 1 or 2 CommissionScheduleLevelID per CommissionScheduleTermID. Take highest only.
	SELECT DISTINCT csd.CommissionScheduleDetailID
		,csd.CommissionScheduleLevelID
		,csd.CarrierProductID
		,csd.CommissionScheduleTypeID
		,csda.CommissionTermID
		,csda.CommissionPercentage
	INTO #CommissionScheduleDetails
	FROM dbo.CommissionScheduleDetails AS csd
	LEFT JOIN dbo.CommissionScheduleDetailAges AS csda
		ON CSDA.CommissionScheduleDetailID = csd.CommissionScheduleDetailID
	INNER JOIN (
		SELECT csd.CarrierProductID, csd.CommissionScheduleTypeID, csda.CommissionTermID, csda.CommissionPercentage
			, MAX(csd.CommissionScheduleLevelID) AS CommissionScheduleLevelID
		FROM dbo.CommissionScheduleDetails AS csd
		LEFT JOIN dbo.CommissionScheduleDetailAges AS csda
			ON CSDA.CommissionScheduleDetailID = csd.CommissionScheduleDetailID
		GROUP BY csd.CarrierProductID, csd.CommissionScheduleTypeID, csda.CommissionTermID, csda.CommissionPercentage
	) AS csda2
		ON csda2.CarrierProductID = csd.CarrierProductID
		AND csda2.CommissionScheduleTypeID = csd.CommissionScheduleTypeID
		AND csda2.CommissionTermID = csda.CommissionTermID
		AND csda2.CommissionPercentage = csda.CommissionPercentage
		AND csda2.CommissionScheduleLevelID = csd.CommissionScheduleLevelID

	IF OBJECT_ID('tempdb..#CommissionSetupDetailsTemp') IS NOT NULL
		DROP TABLE #CommissionSetupDetailsTemp;

	SELECT * INTO #CommissionSetupDetailsTemp FROM dbo.CommissionSetupDetails WHERE WorkflowInstanceID = @WorkflowInstanceID;

	IF EXISTS (SELECT * FROM dbo.CommissionSetupDetails WHERE WorkflowInstanceID = @WorkflowInstanceID)
	BEGIN
		DELETE FROM dbo.CommissionSetupDetails WHERE WorkflowInstanceID = @WorkflowInstanceID
	END

	INSERT dbo.CommissionSetupDetails (
		CommissionSetupID
		,EntityID
		,Source_ProducerID
		,FullName
		,HierarchyPosition
		,GroupProductID
		,CarrierProductID
		,Source_Product
		,Source_ProductTPACode
		,Source_EffectiveDate
		,Source_ExpirationDate
		,Source_FirstYearCommissionID
		,Source_FirstYearCommissionPercent
		,Source_RenewalProducerCommissionID
		,Source_RenewalCommissionPercent
		,Source_LevelCommissionPercent
		,CommissionScheduleDetailID
		,CommissionScheduleDetailID1styearMatch
		,CommissionScheduleDetailIDRenewalMatch
		,CommissionScheduleDetailIDLevelMatch
		,IsDeleted
		,CommissionScheduleDetailID_Override
		,WorkflowInstanceID
		,CommissionSetupNotes
		,CommissionAgentType
		,BaseAgentWritingNumber
		,DirectUplineProducerID
		,SplitPercentage
	)
	SELECT sub.CommissionSetupID
		,sub.EntityID
		,sub.ProducerID
		,sub.FullName
		,sub.HierarchyLevel
		,sub.GroupProductID
		,sub.CarrierProductID
		,sub.Product
		,sub.ProductTPACode
		,sub.EffectiveDate
		,sub.ExpirationDate
		,sub.FirstYearCommissionID
		,sub.FirstYearCommissionPercent
		,sub.RenewalCommissionID
		,sub.RenewalCommissionPercent
		,sub.LevelCommissionPercent
		,CASE 
			WHEN sub.CommissionScheduleDetailIDOverride IS NOT NULL THEN sub.CommissionScheduleDetailIDOverride
			WHEN sub.CommissionScheduleTypeID = 780 THEN COALESCE(sub.CommissionScheduleDetailID1styearMatch, sub.CommissionScheduleDetailIDRenewalMatch, sub.CommissionScheduleDetailIDLevelMatch)
			WHEN sub.CommissionScheduleTypeID = 781 THEN COALESCE(sub.CommissionScheduleDetailIDLevelMatch, sub.CommissionScheduleDetailID1styearMatch, sub.CommissionScheduleDetailIDRenewalMatch)
		END AS CommissionScheduleDetailID
		,sub.CommissionScheduleDetailID1styearMatch
		,sub.CommissionScheduleDetailIDRenewalMatch
		,sub.CommissionScheduleDetailIDLevelMatch
		,@IsDeleted AS IsDeleted
		,COALESCE(@CommissionScheduleDetailID_Override, sub.CommissionScheduleDetailIDOverride) AS CommissionScheduleDetailID_Override
		,sub.WorkflowInstanceID
		,sub.CommissionSetupNotes
		,sub.CommissionAgentType
		,sub.WritingNumber
		,sub.DirectUplineProducerID
		,sub.SplitPercentage
	FROM (
	SELECT piv3.CommissionSetupID
		,piv3.WorkflowInstanceID
		,piv3.ProducerID
		,piv3.EntityID
		,piv3.HierarchyLevel
		,piv3.GroupProductID
		,piv3.CarrierProductID
		,piv3.FullName
		,piv3.EffectiveDate
		,piv3.ExpirationDate
		,piv3.Product
		,piv3.ProductTPACode
		,piv3.CommissionScheduleTypeID
		,MAX(piv3.[IDFirst Year]) AS FirstYearCommissionID
		,MAX(piv3.[PercentFirst Year]) AS FirstYearCommissionPercent
		,MAX(piv3.IDRenewal) AS RenewalCommissionID
		,MAX(piv3.PercentRenewal) AS RenewalCommissionPercent
		,MAX(piv3.LevelizedCommissionPercent) AS LevelCommissionPercent
		,piv3.CommissionScheduleDetailIDOverride
		,MAX(piv3.[24001780]) AS CommissionScheduleDetailID1styearMatch
		,MAX(piv3.[24002780]) AS CommissionScheduleDetailIDRenewalMatch
		,piv3.CommissionScheduleDetailIDLevelMatch
		,piv3.CommissionSetupNotes
		,piv3.CommissionAgentType
		,piv3.WritingNumber
		,piv3.DirectUplineProducerID
		,piv3.SplitPercentage
	FROM (
		SELECT DISTINCT
			sd.CommissionSetupID
			,sd.WorkflowInstanceID
			,upl.EntityID
			,upl.ProducerID
			,upl.HierarchyLevel
			,upl.FullName
			,upl.EffectiveDate
			,upl.ExpirationDate
			,sd.GroupProductID
			,sd.CarrierProductID
			,kpc.Product
			,kpc.ProductTPACode
			,sd.CommissionScheduleTypeID
			,'ID' + kpc.Term AS Term2
			,'Percent' + kpc.Term AS Term3
			,kpc.ProducerCommissionID
			,kpc.CommissionPercent
			,kpc.LevelizedCommissionPercent
			,CASE WHEN upl.HierarchyLevel = 0
				THEN COALESCE(csd3.CommissionScheduleDetailID, csd4.CommissionScheduleDetailID)
			END AS CommissionScheduleDetailIDOverride
			,csd.CommissionScheduleDetailID
			,csd2.CommissionScheduleDetailID AS CommissionScheduleDetailIDLevelMatch
			,sd.CommissionSetupNotes
			,CONVERT(NVARCHAR(15), csd.CommissionTermID) + CONVERT(NVARCHAR(15), csd.CommissionScheduleTypeID) AS DetailIDPivot 
			,sd.CommissionAgentType
			,sd.WritingNumber
			,upl.DirectUplineProducerID
			,sd.SplitPercentage
		FROM #CommissionSetupDetails AS sd
		CROSS APPLY dbo.KG_fn_HierarchyUplineforProducerID (sd.ProducerID, CAST(GETDATE() AS DATE), sd.CarrierID) AS upl
		INNER JOIN dbo.Kemper_ProducerCommissions AS kpc
			ON kpc.ProducerID = upl.ProducerID
			AND kpc.ProductTPACode = sd.CarrierProductCode
		-- Get CommissionScheduleDetailID from OverrideDefaultScheduleLevelID and CommissionScheduleTypeID
		LEFT JOIN #CommissionScheduleDetails AS csd3
			ON csd3.CarrierProductID = sd.CarrierProductID
			AND csd3.CommissionScheduleLevelID = sd.OverrideDefaultScheduleLevelID
			AND csd3.CommissionScheduleTypeID = sd.CommissionScheduleTypeID
		LEFT JOIN #CommissionScheduleDetails AS csd4
			ON csd4.CarrierProductID = sd.CarrierProductID
			AND csd4.CommissionScheduleLevelID = sd.OverrideDefaultScheduleLevelID
			AND csd4.CommissionScheduleTypeID <> sd.CommissionScheduleTypeID
		-- For 1st year and renewal (heap) commissions
		LEFT JOIN #CommissionScheduleDetails AS csd
			ON csd.CarrierProductID = sd.CarrierProductID
			AND (CONVERT(DECIMAL(18,2), csd.CommissionPercentage * 100) = CONVERT(DECIMAL(18,2), kpc.CommissionPercent))
			AND (csd.CommissionScheduleTypeID = CASE kpc.Term
				WHEN 'First Year' THEN 780
				WHEN 'Renewal' THEN 780
				WHEN 'Level' THEN 781
			END)
			AND (csd.CommissionTermID = CASE kpc.Term
				WHEN 'First Year' THEN 24001
				WHEN 'Renewal' THEN 24002
				WHEN 'Level' THEN 24000
			END)
		-- For Level commissions
		LEFT JOIN #CommissionScheduleDetails AS csd2
			ON csd2.CarrierProductID = sd.CarrierProductID
			AND csd2.CommissionPercentage * 100 = CONVERT(FLOAT, kpc.LevelizedCommissionPercent)
			AND csd2.CommissionScheduleTypeID = 781
			AND csd2.CommissionTermID = 24000
		WHERE sd.WorkflowInstanceID = @WorkflowInstanceID
	) AS src
	PIVOT (
		MAX(ProducerCommissionID) FOR Term2 IN ([IDFirst Year], [IDRenewal], [IDLevel])
	) AS piv
	PIVOT (
		MAX(CommissionPercent) FOR Term3 IN ([PercentFirst Year], [PercentRenewal])
	) AS piv2
	PIVOT (
		MAX(CommissionScheduleDetailID) FOR DetailIDPivot IN ([24001780], [24002780])
	) AS piv3
	GROUP BY piv3.CommissionSetupID
		,piv3.CommissionSetupNotes
		,piv3.WorkflowInstanceID
		,piv3.ProducerID
		,piv3.EntityID
		,piv3.HierarchyLevel
		,piv3.GroupProductID
		,piv3.CarrierProductID
		,piv3.FullName
		,piv3.CommissionScheduleTypeID
		,piv3.EffectiveDate
		,piv3.ExpirationDate
		,piv3.Product
		,piv3.ProductTPACode
		,piv3.CommissionScheduleTypeID
		,piv3.CommissionScheduleDetailIDLevelMatch
		,piv3.CommissionScheduleDetailIDOverride
		,piv3.CommissionAgentType
		,piv3.WritingNumber
		,piv3.DirectUplineProducerID
		,piv3.SplitPercentage
	) AS sub
	ORDER BY sub.CommissionSetupID, sub.GroupProductID, sub.HierarchyLevel

	UPDATE csd
	SET csd.CommissionScheduleDetailID_Override = csdf.CommissionScheduleDetailID_Override
		,csd.CommissionSetupDetailNotes = csdf.CommissionSetupDetailNotes
		,csd.IsDeleted = csdf.IsDeleted
	FROM dbo.CommissionSetupDetails AS csd
	INNER JOIN #CommissionSetupDetailsTemp AS csdf
		ON csd.WorkflowInstanceID = csdf.WorkflowInstanceID
		AND csd.CommissionSetupID = csdf.CommissionSetupID 
		AND COALESCE(csd.DirectUplineProducerID, -1) = COALESCE(csdf.DirectUplineProducerID, -1)
		AND csd.Source_ProducerID = csdf.Source_ProducerID
		AND csd.GroupProductID = csdf.GroupProductID
		AND csd.CommissionScheduleDetailID1stYearMatch = csdf.CommissionScheduleDetailID1stYearMatch

	SELECT * FROM dbo.CommissionSetupDetails WHERE WorkflowInstanceID = @WorkflowInstanceID;
END


SELECT DISTINCT
	csd.WorkflowInstanceID
	,csd.CommissionSetupID
	,csd.EntityID
	--,csd.DirectUplineProducerID
	,csd.Source_ProducerID
	,csd.GroupProductID
	,csd.CommissionScheduleDetailID1stYearMatch
FROM dbo.CommissionSetupDetails AS csd


EXEC [dbo].[KG_Agent_Commission_InsertCommissionDetails] 491483

SELECT * FROM dbo.CommissionSetupDetails AS csd WHERE csd.CommissionSetupID = 600176