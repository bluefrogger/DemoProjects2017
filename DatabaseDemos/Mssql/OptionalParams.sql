/*
http://stackoverflow.com/questions/3415582/how-can-i-use-optional-parameters-in-a-t-sql-stored-procedure
*/
CREATE PROCEDURE spDoSearch
    @FirstName varchar(25) = null,
    @LastName varchar(25) = null,
    @Title varchar(25) = null
AS
BEGIN

    IF (@FirstName IS NOT NULL AND @LastName IS NULL AND @Title IS NULL)
        -- Search by first name only
        SELECT ID, FirstName, LastName, Title
        FROM tblUsers
        WHERE
            FirstName = @FirstName

    ELSE IF (@FirstName IS NULL AND @LastName IS NOT NULL AND @Title IS NULL)
        -- Search by last name only
        SELECT ID, FirstName, LastName, Title
        FROM tblUsers
        WHERE
            LastName = @LastName

    ELSE IF (@FirstName IS NULL AND @LastName IS NULL AND @Title IS NOT NULL)
        -- Search by title only
        SELECT ID, FirstName, LastName, Title
        FROM tblUsers
        WHERE
            Title = @Title

    ELSE IF (@FirstName IS NOT NULL AND @LastName IS NOT NULL AND @Title IS NULL)
        -- Search by first and last name
        SELECT ID, FirstName, LastName, Title
        FROM tblUsers
        WHERE
            FirstName = @FirstName
            AND LastName = @LastName

    ELSE
        -- Search by any other combination
        SELECT ID, FirstName, LastName, Title
        FROM tblUsers
        WHERE
                (@FirstName IS NULL OR (FirstName = @FirstName))
            AND (@LastName  IS NULL OR (LastName  = @LastName ))
            AND (@Title     IS NULL OR (Title     = @Title    ))

END