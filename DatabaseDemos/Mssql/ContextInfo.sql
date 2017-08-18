/*
	http://www.sql-server-performance.com/2008/how-to-use-context-info/
	http://www.sqlservercentral.com/articles/T-SQL/2765/
	https://www.mssqltips.com/sqlservertip/4094/phase-out-contextinfo-in-sql-server-2016-with-sessioncontext/
*/

IF OBJECT_ID('TestContextinfo') IS NOT NULL
BEGIN
    DROP TABLE TestContextinfo;
END;

CREATE TABLE TestContextinfo
    (Id INT IDENTITY
    ,Name VARCHAR(50)
    ,InsertedApplication VARCHAR(128)
    );
GO

CREATE TRIGGER trgTestContextinfoIUD ON TestContextinfo
    FOR INSERT, UPDATE, DELETE
AS
	DECLARE
		@CONTEXT_INFO VARBINARY(128)
	   ,@SPID INT;

	--call system Function to get context info
	SELECT
		@CONTEXT_INFO = CONTEXT_INFO(); 
	--Cast the binary data to plain text
	SELECT
		CAST (@CONTEXT_INFO AS CHAR(128)); 

	--Joining with Inserted Table to  update InsertedApplication column
	UPDATE
		TestContextinfo
	SET
		InsertedApplication = CAST (@CONTEXT_INFO AS CHAR(128))
	FROM
		Inserted I
		INNER JOIN TestContextinfo TC ON TC.Id = I.Id;
 
	--Reinitialising Context_info. It can be anything I reinitialised with SPID
	SELECT
		@SPID = @@SPID;
	SET CONTEXT_INFO @SPID;
GO

CREATE PROC spApplication1
AS
DECLARE @CONTEXT_INFO VARBINARY(128);
SELECT
    @CONTEXT_INFO = CAST('spApplication1' + SPACE(128) AS BINARY(128));

--Set the CONTEXT_INFO with the storedprocedure name
SET CONTEXT_INFO @CONTEXT_INFO;
INSERT  INTO TestContextinfo (Name) SELECT 'AAAA';
GO

--(d) Create Sample StoredProcedure 2
CREATE PROC spApplication2
AS
DECLARE @CONTEXT_INFO VARBINARY(128);
SELECT
    @CONTEXT_INFO = CAST('spApplication2' + SPACE(128) AS BINARY(128));
--Set the CONTEXT_INFO with the storedprocedure name
SET CONTEXT_INFO @CONTEXT_INFO;

INSERT  INTO TestContextinfo (Name) SELECT 'BBBB';
GO

--(e) Create Sample StoredProcedure 3
CREATE PROC spApplication3
AS
DECLARE @CONTEXT_INFO VARBINARY(128);
SELECT
    @CONTEXT_INFO = CAST('spApplication3' + SPACE(128) AS BINARY(128));
--Set the CONTEXT_INFO with the storedprocedure name
SET CONTEXT_INFO @CONTEXT_INFO;
INSERT  INTO TestContextinfo (Name) SELECT 'CCCC';
GO

create TRIGGER trgTestContextinfoIUD ON TestContextinfo
FOR INSERT
AS
DECLARE
    @CONTEXT_INFO VARBINARY(128)
   ,@SPID INT
--call system Function to get context info
	SELECT @CONTEXT_INFO = CONTEXT_INFO() 
--Cast the binary data to plain text
	SELECT CAST (@CONTEXT_INFO AS VARCHAR(128)) 

--Joining with Inserted Table to  update InsertedApplication column
	IF CAST (@CONTEXT_INFO AS VARCHAR(128)) = 'spApplication1'
	BEGIN
		INSERT TestContextinfo
		SELECT Name, CAST(@CONTEXT_INFO AS CHAR(128))
		FROM Inserted

--Reinitialising Context_info. It can be anything I reinitialised with SPID
    SELECT @SPID = @@SPID
    SET CONTEXT_INFO @SPID
END 
ELSE
BEGIN
    RAISERROR('This table can be only modified by Application1',16,1)
    ROLLBACK TRAN
    RETURN
END




--https://msdn.microsoft.com/en-us/library/ms187768.aspx
    SELECT * FROM sys.dm_exec_requests
    SELECT * FROM sys.dm_exec_sessions
    SELECT * FROM sys.sysprocesses


	DECLARE @BinVar varbinary(128);  
	SET @BinVar = CAST(REPLICATE( 0x20, 128 ) AS varbinary(128) );  
	SET CONTEXT_INFO @BinVar;  
	SELECT CONTEXT_INFO() AS MyContextInfo;  


--https://msdn.microsoft.com/en-us/library/ms187928.aspx
-- Set context information at start.
SET CONTEXT_INFO 0x125666698456;
GO
-- Perform several nonrelated batches.
EXEC sp_helpfile;
GO
-- Select the context information set several batches earlier.
SELECT CONTEXT_INFO();
GO



SELECT CONVERT(char(8), 0x4E616d65, 0) AS [Style 0, binary to character];  

--The following example shows how Style 1 can force the result  
--to be truncated. The truncation is caused by  
--including the characters 0x in the result.  
SELECT CONVERT(char(8), 0x4E616d65, 1) AS [Style 1, binary to character];  

--The following example shows that Style 2 does not truncate the  
--result because the characters 0x are not included in  
--the result.  
SELECT CONVERT(char(8), 0x4E616d65, 2) AS [Style 2, binary to character];  

--Ways to return context_info you set beforehand
SELECT context_info AS MyCtxInfo
FROM sys.sysprocesses
WHERE spid = @@SPID;  

SELECT context_info   
FROM sys.dm_exec_sessions  
WHERE session_id = @@SPID;

SELECT context_info AS MyCtxInfo
FROM sys.dm_exec_requests
WHERE session_id = @@SPID
	AND request_id = CURRENT_REQUEST_ID();



-- Set a context value before the batch starts.
SET CONTEXT_INFO 0x9999
GO
-- Set a new context value in the batch.
SET CONTEXT_INFO 0x8888

-- Shows the new value available in the
-- sys.dm_exec_requests view while still in the batch.
SELECT context_info as RequestCtxInfoInBatch
FROM sys.dm_exec_requests
WHERE session_id = @@SPID
	AND request_id = CURRENT_REQUEST_ID();

-- Shows the new value available from the
-- CONTEXT_INFO function while still in the batch.
SELECT CONTEXT_INFO() AS FuncCtxInfoInBatch;

-- Shows that the sys.dm_exec_sessions view still
-- returns the old value in the batch.
SELECT context_info AS SessCtxInfoInBatch
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID;

-- Shows the new value available in the
-- sys.sysprocesses view while still in the batch.
SELECT context_info AS ProcsCtxInfoInBatch
FROM sys.sysprocesses
WHERE spid = @@SPID;

-- End the batch.
GO

-- Shows that the sys.dm_exec_sessions view now
-- returns the new value.
SELECT context_info AS SessCtxInfoAfterBatch
FROM sys.dm_exec_sessions
WHERE session_id = @@SPID;


--http://www.sqlservercentral.com/articles/T-SQL/2765/
CREATE TABLE Employees
(
  empid   INT       PRIMARY KEY  NOT NULL,
  empname VARCHAR(25) NOT NULL,
)

select CAST('uspModifyEmployees' as varbinary(128))
select cast (0x7573704D6F64696679456D706C6F79656573 as varchar(128))
GO

CREATE PROC uspModifyEmployees (@action CHAR(1)
                               ,@empid INT
                               ,@empname VARCHAR(25) = NULL)
AS
BEGIN
	SET NOCOUNT ON;
	SET CONTEXT_INFO 0x7573704D6F64696679456D706C6F79656573; 
	IF @action = 'I'
		INSERT  Employees
				(empid, empname)
		VALUES  (@empid, @empname);
	ELSE
		IF @action = 'D'
			DELETE  Employees
			WHERE   empid = @empid;
		ELSE
			IF @action = 'U'
				UPDATE  Employees
				SET     empname = @empname
				WHERE   empid = @empid;
			ELSE
				RAISERROR('Unkown action',16,1);

	SET CONTEXT_INFO 0x0; 
END
/*NOTE: if you forget to reset the CONTEXT_INFO at the end, it is possible to manipulate the table outside the sp since the value you set for CONTEXT_INFO will remain until the connection is closed*/

GO
CREATE  TRIGGER trg_Employees_iud ON Employees
    AFTER INSERT, DELETE, UPDATE
AS
IF @@ROWCOUNT = 0
    RETURN;
--If you use SQL Server 2005 it is better to replace dbo with sys 
IF (SELECT  CAST(context_info AS VARCHAR)
    FROM    master.sys.sysprocesses
    WHERE   spid = @@SPID) <> 'uspModifyEmployees'
BEGIN
    RAISERROR('You can not modify  Employees''s table outside of uspModifyEmployees''s procedure ',16,1);
    ROLLBACK TRAN;
    RETURN;
END; 


-- You want to find how many separate users have logged into your server via ASP pages, but how?
DECLARE @s VARBINARY (128)
SET @s =CAST('Username'AS  VARBINARY(128))
SET CONTEXT_INFO @s

WITH MYcte(username,gp,noconn)
AS  (
SELECT 
	CAST(CONTEXT_INFO AS VARCHAR(128)),
	GROUPING(CAST(CONTEXT_INFO AS VARCHAR(128))),
	COUNT(*) 
FROM 
	sys.dm_exec_sessions
GROUP BY CAST(CONTEXT_INFO AS VARCHAR(128))WITH ROLLUP
)
SELECT   
	username= CASE gp  
						WHEN  1 THEN 'Total connections' 
						ELSE username 
                  END ,
	noconn
FROM MYcte;

