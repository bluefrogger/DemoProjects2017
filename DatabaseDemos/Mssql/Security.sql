/*
https://msdn.microsoft.com/en-us/library/ms189775.aspx
*/

ALTER ROLE buyers WITH NAME = purchasing;  
CREATE ROLE Sales;  
ALTER ROLE Sales ADD MEMBER Barry;  
ALTER ROLE Sales DROP MEMBER Barry;

CREATE LOGIN [alex.yoo] WITH PASSWORD = 'Sunshine9'

GRANT EXECUTE ON OBJECT::HumanResources.uspUpdateEmployeeHireInfo  
    TO Recruiting11;

CREATE USER UserMary FOR LOGIN LoginMary ;  
GO  
EXEC sp_addrolemember 'Production', 'UserMary'  

/*
http://dataeducation.com/blog/basic-impersonation-using-execute-as
*/

