USE [IIM001]
GO

/****** Object:  View [dbo].[vw_Doc1]    Script Date: 7/16/2014 11:25:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create View [dbo].[vw_Doc1] as
SELECT d.ID,
			(SELECT FieldValue FROM [SD_MasterDB].[dbo].[tblSD_Setting] WHERE FieldName = 'ProcessingFolder2') + DB_NAME() + '\$EDD\$NativeFiles\' +
				SUBSTRING(RIGHT('00000000' + cast(d.[ID] as varchar(8)), 8),1,2) + '\' + 
				SUBSTRING(RIGHT('00000000' + cast(d.[ID] as varchar(8)), 8),3,2) + '\' +
				SUBSTRING(RIGHT('00000000' + cast(d.[ID] as varchar(8)), 8),5,2) + '\' +
				SUBSTRING(RIGHT('00000000' + cast(d.[ID] as varchar(8)), 8),7,2) + '.ntv' + 
				CASE WHEN [DocExt] IS NOT NULL THEN '.' + [DocExt] ELSE '' END as 'NTV_PATH',
				c.Name as 'CustodianName', s.SourcePath + s.SourceName as 'EDSource', 
				d.DocOrder, d.AttachPID, d.AttachLvl, d.DocID, d.CustodianID, d.EDSessionID, d.EDSourceID, d.EDFolderID, d.FileType, d.FileDescription, 
				d.FileAccuracy, d.TiffStatus, d.TextXStatus, d.TextPStatus, d.HasExtProps, d.DocExt, d.OrigExt, 
				d.Filename, d.Filesize, d.MD5Hash
FROM tblDoc as d INNER JOIN tblCustodians as c ON d.CustodianID = c.ID
                 INNER JOIN tblEDSources as s ON d.EDSourceID = s.ID
GO


