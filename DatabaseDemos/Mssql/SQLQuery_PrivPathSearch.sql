


USE IIM001_prt3

SET nocount ON;

DECLARE @searchquery NVARCHAR(500)
DECLARE @SearchText NVARCHAR(500)
DECLARE @CommentID VARCHAR(50)
DECLARE @SearchID VARCHAR(50)

IF Object_id('IIM001041_PathName_PrivSearch') IS NOT NULL
  DROP TABLE IIM001041_PathName_PrivSearch

CREATE TABLE IIM001041_PathName_PrivSearch
  (
     id         INT,
     searchID int ,
     commentid  VARCHAR(50),
     searchtext NVARCHAR(4000),
     filename   NVARCHAR(1000),
     path       NVARCHAR(1000)
  )

DECLARE @counter INT

SET @counter = (SELECT Count(*)
                FROM   iim001_total..iim001026_privpathnamesyntax)

WHILE @counter <> 0
  BEGIN
      SELECT @searchquery = searchquery,
                  @searchID  = searchID, 
             @SearchText = searchtext,
             @CommentID = commentid
      FROM   iim001_total..iim001026_privpathnamesyntax
      WHERE  searchid = @counter

      DECLARE @SQLquery NVARCHAR(500)

      IF @CommentID = 1
        BEGIN
            SET @SQLquery = ' insert into IIM001041_PathName_PrivSearch select  a.ID, SearchID = ' + '''' + @SearchID + ''''
                            + ' ,CommentID = ' + '''' + @CommentID
                            + '''' + '  , Term = ' + '''' + @SearchText + ''''
                            + ' ,[Filename],Path  = b.Name   from tblDoc a with(NOlock) inner join tblFolders b with(NOlock) on  a.EDFolderID = b.ID  where   IIM001041_Hit_Fam = 1 and SRM_DocID is not null and ([Filename] like  ' + @searchquery 
                            + 'or b.Name like  ' + @searchquery + '  
                             ) 
                            '
        END

      IF @CommentID = 2
        BEGIN
            SET @SQLquery = ' insert into IIM001041_PathName_PrivSearch select  a.ID, SearchID = ' + '''' + @SearchID + ''''
                            + ' ,CommentID = ' + '''' + @CommentID
                            + '''' + '  ,Term = ' + '''' + @SearchText + ''''
                            + ' ,[Filename],Path  = b.Name   from tblDoc a with(NOlock) inner join tblFolders b with(NOlock) on  a.EDFolderID = b.ID  where IIM001041_Hit_Fam = 1 and SRM_DocID is not null and ( ( [Filename] like  ' + @searchquery
                            + '  COLLATE Latin1_General_BIN)  or (b.Name like  ' + @searchquery + ' COLLATE Latin1_General_BIN))
                             
                            '
        END

      IF @CommentID = 3
        BEGIN
            SET @SQLquery = ' insert into IIM001041_PathName_PrivSearch select  a.ID, SearchID = ' + '''' + @SearchID + ''''
                            + ' ,CommentID = ' + '''' + @CommentID
                            + '''' + '  ,Term = ' + '''' + @SearchText + ''''
                            + ' ,[Filename],Path  = b.Name   from tblDoc a with(NOlock) inner join tblFolders b with(NOlock) on  a.EDFolderID = b.ID  where IIM001041_Hit_Fam = 1 and SRM_DocID is not null and ((b.Name like  ' + @searchquery + ' COLLATE Latin1_General_BIN ))
                             
                            '
        END

      SET @counter = @counter - 1

      exec (@SQLquery)
  END

SELECT a.id,
         b.searchID,
       a.searchtext,
       b.searchquery,
       a.FileName,
       FilePath = replace(a.path,'S:\Irell Manella',''),
       a.commentid,
       b.comment
FROM   IIM001041_PathName_PrivSearch a WITH(nolock)
INNER JOIN iim001_total..iim001026_privpathnamesyntax b WITH(NOLOCK)
ON A.searchID = B.searchID and a.commentid = b.commentid
ORDER  BY a.commentid,
          id,searchID
          
go

