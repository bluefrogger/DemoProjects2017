-----------------------------------------------------------------------------------------------
-- Variable decleration
---------------------------------------------------------------------------------------------
SET NOCOUNT ON;
    declare @curdir nvarchar(800)
    declare @line nvarchar(800)
    declare @command nvarchar(800)
    declare @counter bigint

    DECLARE @1MB    DECIMAL
    SET     @1MB = 1024 * 1024

    DECLARE @1KB    DECIMAL
    SET     @1KB = 1024

---------------------------------------------------------------------------------------------
-- Temp tables creation
---------------------------------------------------------------------------------------------

IF Object_id('tempdb..##dirs') IS NOT NULL
DROP TABLE ##dirs

IF Object_id('tempdb..##tempoutput') IS NOT NULL
DROP TABLE ##tempoutput

IF Object_id('tempdb..##tempFilePaths') IS NOT NULL
DROP TABLE ##tempFilePaths

IF Object_id('tempdb..##tempFileInformation') IS NOT NULL
DROP TABLE ##tempFileInformation

IF Object_id('output') IS NOT NULL
DROP TABLE output


CREATE TABLE ##dirs (DIRID int identity(1,1), directory nvarchar(500))
CREATE TABLE ##tempoutput (line nvarchar(500))
CREATE TABLE output (Directory nvarchar(500), [FileName] nVARCHAR(500), SizeInMB DECIMAL(18,3), SizeInKB DECIMAL(18,3),SizeInB bigint)

CREATE TABLE ##tempFilePaths (Files nVARCHAR(500))
CREATE TABLE ##tempFileInformation (FilePath nVARCHAR(500), FileSize nVARCHAR(500))

--declare @Dir NVARCHAR(max) = 'I:\'

---------------------------------------------------------------------------------------------
-- Call xp_cmdshell
---------------------------------------------------------------------------------------------   

     SET @command = 'dir "'+ @Dir +'" /S/O/B/A:D'
     INSERT INTO ##dirs select @Dir --- Include the root path
     INSERT INTO ##dirs exec xp_cmdshell @command
     INSERT INTO ##dirs SELECT @Dir
     SET @counter = (select count(*) from ##dirs 
where directory is not null   
and directory not like '%RECYCL%'
and directory not like '%\System Volume Informa%' )
     
     DECLARE @Row_count int
     SET @Row_count = (select count(*) from ##dirs
     where directory like '%cannot find the path specified%'
     or directory like '%The network path was not found%'
     OR directory like '%ccess is denie%'
     )
     
     DECLARE @ERROR NVARCHAR(200) 
     SELECT @ERROR = directory FROM ##dirs
     WHERE DIRID = 1
     
      IF @Row_count >= 1
     
      BEGIN
     
      SELECT Error = @ERROR 
     
      END
     
      ELSE
     
                     
 BEGIN
---------------------------------------------------------------------------------------------
-- Process the return data
---------------------------------------------------------------------------------------------     

        WHILE @Counter <> 0
          BEGIN
            DECLARE @filesize bigINT
            SET @curdir = (SELECT directory FROM ##dirs WHERE DIRID = @counter
           and directory is not null   
and directory not like '%RECYCL%'
and directory not like '%\System Volume Informa%'
            )
            SET @command = 'dir "' + @curdir +'" /A'
            ------------------------------------------------------------------------------------------
                -- Clear the table
             DELETE FROM ##tempFilePaths

                INSERT INTO ##tempFilePaths
                EXEC MASTER..XP_CMDSHELL @command

                --delete all directories
                DELETE ##tempFilePaths WHERE Files LIKE '%<dir>%'

                --delete all informational messages
                DELETE ##tempFilePaths WHERE Files LIKE ' %'

                --delete the null values
                DELETE ##tempFilePaths WHERE Files IS NULL

                --get rid of dateinfo
                UPDATE ##tempFilePaths SET files =RIGHT(files,(LEN(files)-20))

                --get rid of leading spaces
                UPDATE ##tempFilePaths SET files =LTRIM(files)

                --split data into size and filename
                ----------------------------------------------------------
                -- Clear the table
               DELETE FROM ##tempFileInformation;

                -- Store the FileName & Size
                INSERT INTO ##tempFileInformation
                SELECT 
                        RIGHT(files,LEN(files) -PATINDEX('% %',files)) AS FilePath,
                        LEFT(files,PATINDEX('% %',files)) AS FileSize
                FROM    ##tempFilePaths
               
           

                --------------------------------
                --  Remove the commas
                UPDATE   ##tempFileInformation
                SET     FileSize = REPLACE(FileSize, ',','')



                --------------------------------------------------------------
                -- Store the results in the output table
                --------------------------------------------------------------

                INSERT INTO output--(FilePath, SizeInMB, SizeInKB)
                SELECT 
                        @curdir,
                        FilePath,
                        CAST(CAST(FileSize AS DECIMAL(18,3))/ @1MB AS DECIMAL(18,3)),
                        CAST(CAST(FileSize AS DECIMAL(18,3))/ @1KB AS DECIMAL(18,3)),
                        FileSize
                FROM    ##tempFileInformation
             
               
            --------------------------------------------------------------------------------------------


            Set @counter = @counter -1
           END


    DELETE FROM OUTPUT WHERE Directory is null      
----------------------------------------------
-- DROP temp tables
----------------------------------------------          
DROP TABLE ##Tempoutput 
DROP TABLE ##dirs 
DROP TABLE ##tempFilePaths 
DROP TABLE ##tempFileInformation
 
--DROP TABLE ##tempfinal 

--;With LST_1 as(
--SELECT  BEGDOC = REVERSE(SUBSTRING(REVERSE([FileName]), CHARINDEX('.', REVERSE([FileName])) + 1, 999))
--,'PATH' = Directory + '\'+[FileName],SizeInMB,SizeInKB,SizeInB FROM  OutPut
--)
--SELECT * FROM LST_1 ORDER BY BEGDOC

--;With LST_2 as(
--SELECT  BEGDOC = REVERSE(SUBSTRING(REVERSE([FileName]), CHARINDEX('.', REVERSE([FileName])) + 1, 999))
--,'PATH' = Directory + '\'+[FileName],SizeInMB,SizeInKB,SizeInB FROM  OutPut
--where sizeinmb > = @Size)
--SELECT * FROM LST_2 ORDER BY BEGDOC

;WITH LST_1 AS(
SELECT  [FileName],  
	CASE WHEN [FileName] like '%.%' then  reverse(left(reverse([FileName]), charindex('.', reverse([FileName])) - 1))
	ELSE '' END AS FileExt 
	,'PATH' = Directory + '\'+[FileName],SizeInMB,SizeInKB,SizeInB 
FROM  OutPut
)
SELECT * FROM LST_1 
ORDER BY [FileName]


--DROP TABLE output

END
