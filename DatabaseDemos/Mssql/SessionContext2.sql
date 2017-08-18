
--https://www.mssqltips.com/sqlservertip/4094/phase-out-contextinfo-in-sql-server-2016-with-sessioncontext/
EXEC sys.sp_helptext @objname = N'sys.sp_set_session_context';
-- returns (server internal)

SELECT  OBJECT_DEFINITION(OBJECT_ID(N'sys.sp_set_session_context'));
-- returns NULL

SELECT  definition
FROM    sys.all_sql_modules
WHERE   object_id = OBJECT_ID(N'sys.sp_set_session_context');
-- returs 0 rows

--You can't even look up the parameters to the procedure; this also returns 0 rows:
SELECT * 
FROM sys.all_parameters
WHERE [object_id] = OBJECT_ID(N'sys.sp_set_session_context');


--MS 2016
--Setting a session variable
--This shows the simple setting of a single session variable:

DECLARE @ID INT = 255;
EXEC sys.sp_set_session_context @key = N'ID', @value = @ID;

SELECT SESSION_CONTEXT(N'ID');

--So, you have to put implicit CONVERT statements anywhere where you're going to use the output for anything other than direct display:
EXEC sys.sp_set_session_context @key = N'a', @value = N'blat';
EXEC sys.sp_set_session_context @key = N'b', @value = N'fung';
SELECT CONCAT(
  CONVERT(NVARCHAR(4000),SESSION_CONTEXT(N'a')), 
  CONVERT(NVARCHAR(4000),SESSION_CONTEXT(N'b'))
);

