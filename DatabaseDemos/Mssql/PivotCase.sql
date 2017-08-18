/*
http://sqlmag.com/t-sql/pivoting-without-aggregation
https://blogs.msdn.microsoft.com/kenobonn/2009/03/22/pivot-on-two-or-more-fields-in-sql-server/
*/

DECLARE @tab TABLE(
	id INT IDENTITY(1,1) NOT NULL
	, col NVARCHAR(50) null
	, val NVARCHAR(50) null
)
INSERT @tab(col, val)
VALUES ('Name', 'Curly'), ('Profession', 'Ninja'), ('Age', '200'), ('Race', 'Human'), ('Home', 'TreeOfLife')

SELECT * FROM @tab

SELECT * FROM (
	SELECT col,
           val 
	FROM @tab
) AS src
PIVOT (
	MIN(val)
	FOR col IN (Name, Profession, Age, Race, Home)
) AS piv

SELECT
	MIN(CASE WHEN col = 'Name' THEN val END) AS Name
	, MIN(CASE WHEN col = 'Profession' THEN val END) AS Profession
	, MIN(CASE WHEN col = 'Age' THEN val END) AS Age
	, MIN(CASE WHEN col = 'Race' THEN val END) AS Race
	, MIN(CASE WHEN col = 'Home' THEN val END) AS Home
FROM @tab

--SQL to create tables and insert data here…
DECLARE @Pet Table
(
  PetID INT
, OwnerID INT --FK to fictitious PetOwner table
, PetName NVARCHAR(50)
, AnimalType NVARCHAR(10)
)
DECLARE @PetDetail Table
(
  PetDetailID INT
, PetID INT -- FK to @Pet table
, DetailType NVARCHAR(50)
, DetailValue NVARCHAR(50)
)
INSERT INTO @Pet(PetID, OwnerID, PetName, AnimalType) VALUES
  (1, 1, 'Sonya', 'Dog')
, (2, 2, 'Bessy', 'Cat')
, (3, 2, 'Speedy', 'Cat')
, (4, 3, 'Nema', 'Cat')
, (5, 3, 'Milo', 'Cat')
, (6, 3, 'Naala', 'Cat')
INSERT INTO @PetDetail(PetDetailID, PetID, DetailType, DetailValue) VALUES
  (1, 1, 'Breed', 'Norwegian Samoyed')
, (2, 1, 'Gender', 'F')
, (3, 2, 'Breed', 'Holstein Hybrid')
, (4, 2, 'Gender', 'F')
, (5, 3, 'Breed', 'DSH')
, (6, 3, 'Gender', 'F')
, (7, 4, 'Breed', 'Manx')
, (8, 4, 'Gender', 'M')
, (9, 5, 'Breed', 'DSH')
, (10, 5, 'Gender', 'F')
, (11, 6, 'Breed', 'Lynx-Point Siamese')
, (12, 6, 'Gender', 'F')

--SELECT 
--      p.OwnerID
--      , p.PetName
--      , p.AnimalType 
--      , pd.DetailType
--      , pd.DetailValue
--      ,pd.DetailType + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNumber]
--      ,'PetName' + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNamePivot]
--FROM @Pet p
--INNER JOIN @PetDetail pd ON p.PetID = pd.PetID

--SELECT 
--      p.OwnerID
--      , p.PetName
--      , p.AnimalType 
--      , pd.DetailType
--      , pd.DetailValue
--      ,pd.DetailType + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNumber]
--      ,'PetName' + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNamePivot]
--FROM @Pet p
--INNER JOIN @PetDetail pd ON p.PetID = pd.PetID

--SELECT PetID, OwnerID, PetName, AnimalType FROM @Pet ORDER BY PetID
--SELECT PetDetailID, PetID, DetailType, DetailValue FROM @PetDetail ORDER BY PetDetailID 

--Simple Join SQL HERE… 
SELECT p.OwnerID, p.PetName, p.AnimalType 
	, pd.DetailType, pd.DetailValue
	,DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS [Pet#]
	,RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS [Pet# by RANK]
FROM @Pet p
INNER JOIN @PetDetail pd ON p.PetID = pd.PetID
ORDER BY p.OwnerID, p.PetName, pd.DetailType

SELECT 
      p.OwnerID
      , p.PetName
      , p.AnimalType 
      , pd.DetailType
      , pd.DetailValue
      ,pd.DetailType + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNumber]
      ,'PetName' + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNamePivot]
FROM @Pet p
INNER JOIN @PetDetail pd ON p.PetID = pd.PetID

--aPIVOT QUERY HERE… 
--SELECT 
--	OwnerID
--	, AnimalType
--	--,petname1
--	--,gender1
--	--,Pivot2.PetName2
--	--,gender2
--	, Pet1Name = MAX([PetName1])
--	, Pet1Gender = MAX([Gender1])
--	, Pet1Breed = MAX([Breed1])
--	, Pet2Name = MAX([PetName2])
--	, Pet2Gender = MAX([Gender2])
--	, Pet2Breed = MAX([Breed2])
--	, Pet3Name = MAX([PetName3])
--	, Pet3Gender = MAX([Gender3])
--	, Pet3Breed = MAX([Breed3])
--FROM (
SELECT * FROM (
SELECT 
      p.OwnerID
      , p.PetName
      , p.AnimalType 
      , pd.DetailType
      , pd.DetailValue
      ,pd.DetailType + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNumber]
      ,'PetName' + CAST(DENSE_RANK() OVER (PARTITION BY p.OwnerID ORDER BY p.PetName ASC) AS NVARCHAR) AS [PetNamePivot]
FROM @Pet p
INNER JOIN @PetDetail pd ON p.PetID = pd.PetID
) AS query
PIVOT (MAX(PetName)
      FOR PetNamePivot IN ([PetName1],[PetName2],[PetName3])) AS Pivot2
PIVOT (MAX(DetailValue)
      FOR PetNumber IN ([Gender1],[Gender2],[Gender3], [Breed1], [Breed2], [Breed3])) AS Pivot1
--GROUP BY
--  OwnerID
--, AnimalType
--ORDER BY OwnerID

-----------------------------------------------------------------------------------------------
