DECLARE @birthdate DATETIME = '2000-09-01'

SELECT CASE
		WHEN DATEADD(year, DATEDIFF(year, @birthdate, GETDATE()), @birthdate) > GETDATE() THEN DATEDIFF(YEAR, @birthdate, GETDATE()) - 1
		WHEN DATEADD(year, DATEDIFF(year, @birthdate, GETDATE()), @birthdate) <= GETDATE() THEN DATEDIFF(YEAR, @birthdate, GETDATE())
	END
    
SELECT CASE
		WHEN DATEADD(year, DATEDIFF(year, @birthdate, GETDATE()), @birthdate) > GETDATE() THEN DATEDIFF(YEAR, @birthdate, GETDATE()) - 1
		ELSE DATEDIFF(YEAR, @birthdate, GETDATE())
	END	

