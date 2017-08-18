USE AdventureWorks2008R2
SELECT      CAT.Name AS [Category],
            STUFF((    SELECT ',' + SUB.Name AS [text()]
                        – Add a comma (,) before each value
                        FROM Production.ProductSubcategory SUB
                        WHERE
                        SUB.ProductCategoryID = CAT.ProductCategoryID
                        FOR XML PATH('') – Select it as XML
                        ), 1, 1, '' )
                        – This is done to remove the first character (,)
                        – from the result
            AS [Sub Categories]
FROM  Production.ProductCategory CAT
