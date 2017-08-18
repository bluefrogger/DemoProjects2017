-- batch delete 

SET NOCOUNT ON
WHILE 1 = 1
    BEGIN
        DELETE TOP ( 10 )
        FROM    etl.NameColor
        WHERE   Name BETWEEN 'aa' AND 'll'
    END

-- batch insert if not in archive
DECLARE @BatchSize INT = 10000

WHILE 1 = 1
    BEGIN
        INSERT  etl.NameColor --with(tablock) in 2008 for minimal logging
                (Name
                ,Color
	            )
        SELECT TOP ( @BatchSize )
                ss.id
                ,ss.Name
                ,ss.Color
        FROM    etl.NameColor AS ss
        WHERE   NOT EXISTS ( SELECT *
                                FROM   etl.NameColorArchive AS aa --need ts in archive since duplicate id
                                WHERE  aa.id = ss.id --need non clustered index on both table(id)
	)
        IF @@rowcount < @BatchSize
            BREAK
    END
GO

-- Insert Default

CREATE TABLE dbo.test(
	id INT DEFAULT 9
)

INSERT dbo.test DEFAULT VALUES
DROP TABLE dbo.test
