-- http://sqlserverplanet.com/tsql/create-index-on-table-variable

Creating an index on a table variable can be done implicitly within the declaration of the table variable by defining a primary key and creating unique constraints. 
The primary key will represent a clustered index, while the unique constraint a non clustered index.
    DECLARE @Users TABLE
    (
        UserID  INT PRIMARY KEY,
        UserName VARCHAR(50),
        UNIQUE (UserName)
    )

The drawback is that the indexes (or constraints) need to be unique. One potential way to circumvent this however, is to create a composite unique constraint:
    DECLARE @Users TABLE
    (
        UserID  INT PRIMARY KEY,
        UserName VARCHAR(50),
        FirstName VARCHAR(50),
        UNIQUE (UserName,UserID)
    )

You can also create the equivalent of a clustered index. To do so, just add the clustered reserved word.
    DECLARE @Users TABLE
    (
        UserID  INT PRIMARY KEY,
        UserName VARCHAR(50),
        FirstName VARCHAR(50),
        UNIQUE CLUSTERED (UserName,UserID)
    )

Generally, temp tables perform better in situations where an index is needed. 
The downfall to temp tables is that they will frequently cause recompilation. 
This was more of an issue with SQL 2000 when compilation was performed at the procedure level instead of the statement level. 
SQL 2005 and above perform compilation at the statement level so if only one statement utilizes a temp table then 
that statement is the only one that gets recompiled. Contrary to popular belief, table variables can and do write to disk. 


DECLARE @tab TABLE (
	id INT IDENTITY(1,1)
	,life NVARCHAR(20) INDEX ci_tab_life CLUSTERED
)

--table variable with clustered index on non key
DECLARE @tab2 TABLE (
	id INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED
	,life NVARCHAR(20) UNIQUE CLUSTERED
)

DECLARE @tab3 TABLE (
	id INT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED
	,life NVARCHAR(20) INDEX ci_tab3_life CLUSTERED
)
