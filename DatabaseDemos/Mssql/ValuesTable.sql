/*
You can use VALUES to create objects on the fly, see examples below. Maybe this will come in handy one day.
*/
/***********************************************************************/
DECLARE @FileName NVARCHAR(256) = 'Feb report 2016.xlsx'

/* as a table */
;WITH Months AS
(
	SELECT TOP (12) RIGHT('0' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT null)) AS VARCHAR(3)), 2) AS MM
		,DATENAME(mm, DATEADD(MM, ROW_NUMBER() OVER (ORDER BY (SELECT null)) - 1, '1900-01-01')) AS MonthNames
	FROM master.sys.columns
)
SELECT fn.Files
	,SUBSTRING(fn.Files, PATINDEX('%[0-9]%', fn.Files), 4)
		+ mo.MM + '01' AS YYYYMMDD
	,xafn.Files
FROM (VALUES(@FileName)) AS fn(Files)
LEFT JOIN Months AS mo
--FROM months mm
--INNER JOIN (VALUES (@FileName)) fn(Files)		/*in joins*/
	ON LEFT(fn.Files, 3) = LEFT(mo.MonthNames, 3)
CROSS APPLY (VALUES (@FileName)) AS xafn(Files)
--WHERE LEFT(fn.Files, 3) = LEFT(mo.MonthNames, 3)		/*in cross apply*/
GO
/***********************************************************************/

INSERT dbo.Patient_Charts (ChartID, PatientID, ChartTypeID, ChartNotes)
SELECT TOP(100) pch.Id, pma.Id, pct.Id, pc.ChartNotes
FROM (VALUES(0, 0, 0, 0)) AS main(ChartId, PatientID, ChartTypeID, ChartNotes)
CROSS APPLY (
	SELECT ROW_NUMBER() OVER(ORDER BY(SELECT null))
	FROM sys.tables
) AS pch(Id)
CROSS APPLY (
	SELECT pm.PatientID
	FROM dbo.Patients_Main AS pm
	WHERE pm.PatientID = pch.Id % 2 + 1
) AS pma(Id)
CROSS APPLY (
	SELECT pct.ChartTypeId
	FROM dbo.Patients_ChartTypes AS pct
	WHERE pct.ChartTypeId= pch.Id % 3 + 1
) AS pct(Id)
CROSS APPLY (
	SELECT pc.ChartNotes
	FROM dbo.Patients_Charts AS pc
	WHERE pc.ChartId= pch.Id % 100 + 1
) AS pc(ChartNotes)

SELECT * FROM dbo.Patients_Charts AS pct
INSERT dbo.Patients_ChartTypes (Description)
VALUES  ('aaa'), ('bbb'), ('ccc')
