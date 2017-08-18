A way to identify how dirty our data in the member mart really is (looking for non-alphabet characters)

Execute in YBCM1S1.DAR_Members

WITH specialchars AS
(
SELECT ROW_NUMBER() OVER (ORDER BY FirstName) ID
      , FirstName + LastName String
      , FirstName
      , LastName
FROM support.DW_Patients_XW
WHERE PATINDEX('%[^A-Z]%', FirstName) > 0
      OR PATINDEX('%[^A-Z]%', LastName) > 0
)
, tally AS
(
SELECT ROW_NUMBER() OVER (ORDER BY c1.column_id) N
FROM master.sys.columns c1
CROSS JOIN master.sys.columns c2
)
, chartable AS
(
SELECT 0 N, CHAR(0) [Char]
UNION ALL
SELECT N + 1, CHAR(N + 1)
FROM chartable
WHERE N < 255
)

SELECT ca.[Char]
      , COUNT(*) Occurances
      , cc.N ASCII_DEC
FROM tally tt
CROSS APPLY (SELECT ss.ID, SUBSTRING(ss.String,N,1) [Char]
                  FROM specialchars ss
                  WHERE tt.N <= LEN(ss.String)
                  ) ca
LEFT JOIN chartable cc
      ON ca.Char = cc.Char
WHERE PATINDEX('%[^A-Z]%', ca.[Char]) > 0
GROUP BY ca.[Char], cc.N
ORDER BY COUNT(*) DESC
OPTION (MAXRECURSION 0)
