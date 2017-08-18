SELECT * FROM [dbo].[KG_fn_HierarchyUplineforProducerID](35733, GETDATE(), 'KB')

SELECT cs.WorkflowInstanceID, kp.ProducerID, eei2.EntityExternalIdentID, eei2.EntityID
		, eei2.CarrierID, eei2.ExternalIdentTypeID, eei2.ExternalIdentifier,eei2.Notes
		, kp.FirstName + ' ' + kp.LastName
	FROM dbo.CommissionSetup AS cs
	INNER JOIN dbo.Kemper_Producers AS kp
		ON kp.WritingNumber = cs.WritingNumber
	--INNER JOIN dbo.EntityExternalIdents AS eei
	--	ON eei.EntityExternalIdentID = cs.EntityExternalIdentID
	INNER JOIN dbo.EntityExternalIdents AS eei2
		ON CAST(kp.ProducerID AS NVARCHAR(255)) = eei2.ExternalIdentifier
	WHERE cs.WorkflowInstanceID = 491167