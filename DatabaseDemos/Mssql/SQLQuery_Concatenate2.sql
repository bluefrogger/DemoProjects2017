GO

USE AlexTest

SELECT ID
	,LEFT(SearchText, LEN(SearchText) - 1) AS SearchText
FROM (
	SELECT ID
		,(
			SELECT SearchText + '; ' AS [text()]
			FROM dbo.IIM001026_IIM001_prt2_InSens_List1_Search AS internal -- Change Table name
			WHERE internal.ID = ID.ID
			GROUP BY SearchText
			FOR XML PATH('')
			) AS SearchText
	FROM (
		SELECT ID
		FROM dbo.IIM001026_IIM001_prt2_InSens_List1_Search -- Change Table name
		GROUP BY ID
		) AS ID
	) AS pre_trimmed
ORDER BY ID
	,SearchText

