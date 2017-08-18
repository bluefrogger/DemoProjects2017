
DECLARE @i INT = 0, @BillingDate INT;

WHILE @i < 100000
BEGIN
    SET @i = @i + 1;
    SET @BillingDate = CAST(RAND() * 10000 AS INT) % 3650; --number of days less than 10 years

    INSERT  test.BillingInfo
            (BillingDate
            ,BillingAmt
            )
    VALUES  (DATEADD(dd, @BillingDate, CAST('1999-01-01' AS SMALLDATETIME))
            ,RAND() * 5000 --random amount 0 - 5000 exclusive
	        );
END;

SELECT TOP 100
        ROW_NUMBER() OVER ( ORDER BY ( SELECT   NULL
                                     ) ) AS SaleID
       ,NEWID() AS ProductID
       ,ABS(CHECKSUM(NEWID())) AS Quantity
       ,SQL_VARIANT_PROPERTY(ABS(CHECKSUM(NEWID())), 'basetype') AS datatype
       ,CAST(CAST(NEWID() AS VARBINARY) AS INT) AS SaleAmount
       ,DATEADD(dd, ABS(CHECKSUM(NEWID()) % 3650), '2000-01-01') AS SaleDate
FROM    sys.columns AS aa
        CROSS JOIN sys.columns AS bb;

