IF OBJECT_ID('tempdb..#XmlTestTable') IS NOT NULL DROP TABLE #XmlTestTable
CREATE TABLE #XmlTestTable 
(
    ID INT PRIMARY KEY IDENTITY(1,1),
    FirstName VARCHAR(20),
    LastName VARCHAR(20)
)
INSERT INTO #XmlTestTable (FirstName,LastName) VALUES
('John','Doe'),
('Jane','Doe'),
('Brian','Smith'),
('Your','Mom')

--YOUR TESTS
SELECT * FROM #XmlTestTable FOR XML AUTO
SELECT * FROM #XmlTestTable FOR XML AUTO, ELEMENTS
SELECT * FROM #XmlTestTable FOR XML RAW
SELECT * FROM #XmlTestTable FOR XML RAW, ELEMENTS
SELECT * FROM #XmlTestTable FOR XML PATH('Customers')
SELECT * FROM #XmlTestTable FOR XML PATH('')

DROP TABLE #XmlTestTable

--https://social.msdn.microsoft.com/Forums/sqlserver/en-US/c4d29985-4cef-4811-8d68-c4d3fa9365ca/using-text-directive-with-for-xml-path?forum=sqlxml
--http://www.sqlservercentral.com/blogs/dwainsql/2014/03/27/tally-tables-in-t-sql/
USE AW2014
-- Blank path with text()
SELECT LastName AS [text()] FROM Person.Person FOR XML PATH('');
SELECT (
	SELECT LastName FROM Person.Person FOR XML PATH(''), TYPE
	).value('.', 'nvarchar(2000)');
SELECT sub.LN.value('.', 'nvarchar(2000)')
FROM (
	SELECT LastName FROM Person.Person FOR XML PATH(''), TYPE
	) sub(LN)

-- Explicit path with text()
SELECT LastName AS [text()] FROM Person.Person   FOR XML PATH('node');
-- Explicit path without text()
SELECT LastName FROM Person.Person   FOR XML PATH('node');

