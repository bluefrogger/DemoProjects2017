USE master

DECLARE @db NVARCHAR(50) = 'coreDev.SolutaHealth.com'
DECLARE @ts NVARCHAR(50) = REPLACE(REPLACE(LEFT(CONVERT(NVARCHAR(50), GETDATE(), 127), 16), '-', '_'), ':', '_')
DECLARE @Path NVARCHAR(100) = '\\NFS3\DatabaseBackup\ShSql1\' + @db + '_' + @ts + '.bak'

BACKUP DATABASE @db
TO DISK = @Path
WITH COPY_ONLY, FORMAT
