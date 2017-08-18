

/*************************************************************************************
 Code from the SQL Server Central article titled "Solving the "Running Total" & 
 "Ordinal Rank" Problems in SQL Server 2000 and 2005 (Rewritten)" by Jeff Moden, 
 10 October 1009.
*************************************************************************************/

--CODE FROM FIGURE 2 - Build the Test Table
/*************************************************************************************
 Create the test table with a non-clustered Primary Key and a separate clustered index
 This code has been tested in SQL Server 2000 and 2005.
*************************************************************************************/
--===== Do this testing in a nice, "safe" place that everyone has
    USE TempDB
GO
--===== If the test table already exists, drop it in case we need to rerun.
     -- The 3 part naming is overkill, but prevents accidents on real tables.
     IF OBJECT_ID('TempDB.dbo.TransactionDetail') IS NOT NULL
        DROP TABLE TempDB.dbo.TransactionDetail
GO
--===== Create the test table (TransactionDetail) with a NON clustered PK
 CREATE TABLE dbo.TransactionDetail
        (
        TransactionDetailID INT IDENTITY(1,1), --Temporal "tie-breaker"
        Date                DATETIME,
        AccountID           INT,
        Amount              MONEY,
        AccountRunningTotal MONEY,  --Running total across each account
        AccountRunningCount INT,    --Like "Rank" across each account
        NCID                INT,    --For "proof" later in the article
        CONSTRAINT PK_TransactionDetail_TransactionDetailID
                   PRIMARY KEY NONCLUSTERED (TransactionDetailID) 
                   WITH FILLFACTOR = 100
        )
GO
--===== Add a clustered index that will easily cause page splits because
     -- of the randomized data being inserted.  This index also represents
     -- the expected sort order of most of the code examples.
 CREATE CLUSTERED INDEX IXC_Transaction_AccountID_Date_TransactionDetailID
     ON dbo.TransactionDetail (AccountID, Date, TransactionDetailID)

--===== Add a non-clustered index on the NCID column sorted in 
     -- descending order.  This is for some "proofs" later on
     -- in the article.
 CREATE NONCLUSTERED INDEX IX_Transaction_NCID
     ON dbo.TransactionDetail (NCID DESC)
GO
--CODE FROM FIGURE 3 - Populate the Test Table in a Highly Randomized Fashion
/*************************************************************************************
 Populate the table using a rather slow method but one that's sure to cause lots of
 Page splits and that will fragment the table with over 99% fragmentation.
*************************************************************************************/
--===== Preset the environment for appearance and speed
    SET NOCOUNT ON

--===== Populate the table in "segments" to force page splits.
     -- Normally this would NOT have a While loop in it.
     -- Because the While loop is there and page splits are happening,
     -- this takes a whopping 00:02:50 to create on my box.
  WHILE (ISNULL(IDENT_CURRENT('TransactionDetail'),0)) < 100000
  BEGIN
         INSERT INTO dbo.TransactionDetail
                (Date, AccountID, Amount)
         SELECT TOP 10000
                --10 years worth of dates with times from 1/1/2000 to 12/31/2009
                CAST(RAND(CHECKSUM(NEWID()))*3653.0+36524.0 AS DATETIME) AS Date,
                --100 different account numbers
                ABS(CHECKSUM(NEWID()))%100+1,
                --Dollar amounts from -99.99 to + 99.99
                CAST(CHECKSUM(NEWID())%10000 /100.0 AS MONEY)
           FROM Master.dbo.SysColumns sc1
          CROSS JOIN Master.dbo.SysColumns sc2
    END
	select * from dbo.TransactionDetail
--===== Update the NCID column to be the reverse of the TransactionDetailID column
 UPDATE dbo.TransactionDetail
    SET NCID = 100000 - TransactionDetailID + 1
GO
--CODE FROM FIGURE 4 - Check for Fragmentation and Page Splits
/*************************************************************************************
 Show the fragmentation and the page splits
*************************************************************************************/
--===== Look for the "Logical Scan Fragmentation" here... 
     -- The higher the number, the worse the fragmentation is.
     -- Also notice the average page density is just a little over half full.
     -- The output from this command will show in the "Messages" tab.
   DBCC SHOWCONTIG ('TransactionDetail')
   select * from sys.dm_db_index_physical_stats(null,null,null,null,null)
--===== If you compare "PagePID" to "PrevPagePID" and "NextPagePID", you can see that
     -- many page splits took place.  In an "unsplit" index, the PrevPagePID will
     -- usually be 1 less than the PagePid and the NextPagePID be 1 more than the 
     -- PagePID.  If they are not, there's a good chance that a page split occurred.
     -- The output from this command will will show either in the "Grid/Results" tab 
     -- or in the "Messages" tab if in the text mode.
   DBCC IND (0, 'TransactionDetail', 1)
GO
--CODE FROM FIGURE 6 - Cursor to Solve the Running Total Problem
/*************************************************************************************
 Straight forward cursor method to calculate the running total for each AccountID.
 Runs in almost 8 minutes on the million row test table on my 7 year old desktop 
 computer.
*************************************************************************************/
--===== Suppress the auto-display of row counts for speed an appearance
   SET NOCOUNT ON
   select * from dbo.TransactionDetail
--===== Declare the cursor storage variables
DECLARE @Amount              MONEY
DECLARE @CurAccountID        INT

--===== Declare the working variables
DECLARE @PrevAccountID       INT
DECLARE @AccountRunningTotal MONEY

--===== Create the cursor with rows sorted in the correct
     -- order to do the running balance by account
DECLARE curRunningTotal CURSOR LOCAL FORWARD_ONLY
    FOR
 SELECT AccountID, Amount
   FROM dbo.TransactionDetail
--  WHERE AccountID <= 10 --Uncomment for "short" testing
  ORDER BY AccountID, Date, TransactionDetailID

   OPEN curRunningTotal

--===== Read the information from the first row of the cursor
  FETCH NEXT FROM curRunningTotal
   INTO @CurAccountID, @Amount

--===== For each account, update the account running total 
     -- column until we run out of rows.  Notice that the
     -- CASE statement resets the running total at the 
     -- start of each account.
  WHILE @@FETCH_STATUS = 0
  BEGIN

--===== Calculate the running total for this row
     -- and remember this AccountID for the next row
 SELECT @AccountRunningTotal = CASE 
                               WHEN @CurAccountID = @PrevAccountID 
                               THEN @AccountRunningTotal + @Amount 
                               ELSE @Amount 
                               END,
        @PrevAccountID = @CurAccountID

--===== Update the running total for this row
 UPDATE dbo.TransactionDetail 
    SET AccountRunningTotal = @AccountRunningTotal
  WHERE CURRENT OF curRunningTotal

--===== Read the information from the next row of the cursor
  FETCH NEXT FROM curRunningTotal
   INTO @CurAccountID, @Amount

    END --End of the cursor

--======== Housekeeping
     CLOSE curRunningTotal
DEALLOCATE curRunningTotal
GO
--CODE FROM FIGURE 7 - Code to Verify the Account Running Total
USE TEMPDB
GO
CREATE PROCEDURE dbo.Verify AS
/*************************************************************************************
 Code to verify that the account running total calculation worked correctly.
 Please read the comments to see how it works.
*************************************************************************************/
--===== Conditionally drop the verification table to make
     -- it easy to rerun the verification code
     IF OBJECT_ID('TempDB..#Verification') IS NOT NULL
   DROP TABLE dbo.#Verification

--===== Define a variable to remember the number of rows
     -- copied to the verification table
DECLARE @MyCount INT

--===== Copy the data from the test table into the
     -- verification table in the correct order.
     -- Remember the correct order with an IDENTITY.
 SELECT IDENTITY(INT,1,1) AS RowNum,
        AccountID,
        Amount,
        AccountRunningTotal
   INTO #Verification
   FROM dbo.TransactionDetail
  ORDER BY AccountID, Date, TransactionDetailID

--===== Remember the number of rows we just copied
 SELECT @MyCount = @@ROWCOUNT

--===== Check the running total calculations
 SELECT CASE 
            WHEN COUNT(hi.RowNum) + 1 = @MyCount
            THEN 'Account Running Total Calculations are correct'
            ELSE 'There are some errors in the Account Running Totals'
        END
   FROM #Verification lo
  INNER JOIN
        #Verification hi
     ON lo.RowNum + 1 = hi.RowNum
  WHERE (-- Compare lines with the same AccountID
         hi.AccountID = lo.AccountID
         AND hi.AccountRunningTotal = lo.AccountRunningTotal + hi.Amount)
     OR
        (-- First line of account has running total same as amount
         hi.AccountID <> lo.AccountID
         AND hi.AccountRunningTotal = hi.Amount)
GO
--CODE FROM FIGURE 8 - Code to Verify the Running Total
--===== Verify the the running total worked on the 
     -- TransactionDetail table
    USE TEMPDB --Takes 10 seconds on my machine
   EXEC dbo.Verify
GO
--CODE FROM FIGURE 9 - Code to Reset the Running Total Columns
/**************************************************************************************
 This stored procedure will clear the calculated columns in the test table without
 disturbing the randomized data in the table so that we can repeat tests and use
 different methods without changing the test data.
**************************************************************************************/
    USE TEMPDB
GO
 CREATE PROCEDURE dbo.ResetTestTable AS
 UPDATE dbo.TransactionDetail
    SET AccountRunningTotal = NULL,
        AccountRunningCount = NULL
GO
--CODE FROM FIGURE 10 - EXEC to Clear the Running Total Columns
EXEC dbo.ResetTestTable
GO
--CODE FROM FIGURE 11 - Triangular Join Running Total
/*************************************************************************************
 This does a running total using the "Triangular Join" method.  It looks "Set-Based"
 because there's no explicit loop declared.  In fact, it's RBAR ON STEROIDS!
*************************************************************************************/ 
 SELECT td.AccountID,
        td.Date,
        td.TransactionDetailID,
        td.Amount,
        (--==== Triangular join to get the sum of previous rows for each row
         SELECT SUM(td2.Amount) 
           FROM dbo.TransactionDetail td2 
          WHERE td2.AccountID = td.AccountID
            AND td2.Date     <= td.Date
        ) AS AccountRunningTotal
   FROM dbo.TransactionDetail td
  WHERE td.AccountID = 1
  ORDER BY td.AccountID, td.Date, td.TransactionDetailID
GO
--CODE FROM FIGURE 12 - Simple SELECT: What does it do behind the scenes?
 SELECT *
   FROM TempDB.dbo.TransactionDetail
GO
--CODE FROM FIGURE 13 - Simple UPDATE:  What does it do behind the scenes?
 UPDATE TempDB.dbo.TransactionDetail
    SET AccountRunningCount = NULL
GO
--CODE FROM FIGURE 14 - "Quirky" Update Produces a Running Count
--===== "Quirky Update" shows us the order that an UPDATE uses.
     -- Notice that on my box, this only takes 6 seconds
DECLARE @Counter INT
 SELECT @Counter = 0

 UPDATE TempDB.dbo.TransactionDetail
    SET @Counter = AccountRunningCount = @Counter + 1
   FROM TempDB.dbo.TransactionDetail WITH (TABLOCKX)
 OPTION (MAXDOP 1)
GO
--CODE FROM FIGURE 16 - Manually Verify the Running Count
--===== Select all the rows in order by the clustered index
 SELECT *
   FROM TempDB.dbo.TransactionDetail
  ORDER BY AccountID, Date, TransactionDetailID
GO
--CODE FROM FIGURE 17 – An Important Index Hint.
--===== "Quirky Update" with index hint to guarantee exclusive
     -- use of the table.
DECLARE @Counter INT
 SELECT @Counter = 0

 UPDATE TempDB.dbo.TransactionDetail
    SET @Counter = AccountRunningCount = @Counter + 1
   FROM TempDB.dbo.TransactionDetail WITH (TABLOCKX)
OPTION (MAXDOP 1)
GO
--Clear the calculated columns again.
EXEC dbo.ResetTestTable
GO
--CODE FROM FIGURE 18 - Code for the "Quirky Update" Running Total
/*************************************************************************************
 Pseduo-cursor Running Total update using the "Quirky Update" takes about 4 seconds
 on my box.
*************************************************************************************/
--===== Supress the auto-display of rowcounts for speed an appearance
   SET NOCOUNT ON

--===== Declare the working variables
DECLARE @PrevAccountID       INT
DECLARE @AccountRunningTotal MONEY

--===== Update the running total for this row using the "Quirky Update"
     -- and a "Pseudo-cursor"
 UPDATE dbo.TransactionDetail 
    SET @AccountRunningTotal = AccountRunningTotal = CASE 
                                                     WHEN AccountID = @PrevAccountID 
                                                     THEN @AccountRunningTotal+Amount 
                                                     ELSE Amount 
                                                     END,
        @PrevAccountID = AccountID
   FROM dbo.TransactionDetail WITH (TABLOCKX)
 OPTION (MAXDOP 1)
GO
--Clear the calculated columns again.
EXEC dbo.ResetTestTable
GO
--CODE FROM FIGURE 19 - The "Quirky Update" Running Total and Running Count
/*************************************************************************************
 Pseduo-cursor update using the "Quirky Update" to calculate both Running Totals and
 a Running Count that start over for each AccountID.
 Takes 24 seconds with the INDEX(0) hint and 6 seconds without it on my box.
*************************************************************************************/
--===== Supress the auto-display of rowcounts for speed an appearance
   SET NOCOUNT ON

--===== Declare the working variables
DECLARE @PrevAccountID       INT
DECLARE @AccountRunningTotal MONEY
DECLARE @AccountRunningCount INT

--===== Update the running total and running count for this row using the "Quirky 
     -- Update" and a "Pseudo-cursor". The order of the UPDATE is controlled by the
     -- order of the clustered index.
 UPDATE dbo.TransactionDetail 
    SET @AccountRunningTotal = AccountRunningTotal = CASE 
                                                     WHEN AccountID = @PrevAccountID 
                                                     THEN @AccountRunningTotal + Amount 
                                                     ELSE Amount 
                                                     END,
        @AccountRunningCount = AccountRunningCount = CASE 
                                                     WHEN AccountID = @PrevAccountID 
                                                     THEN @AccountRunningCount + 1 
                                                     ELSE 1 
                                                     END,
        @PrevAccountID = AccountID
   FROM dbo.TransactionDetail WITH (TABLOCKX)
Where accountID = 1
OPTION (MAXDOP 1)
GO
--CODE FROM FIGURE 20 - Verifying the Running Total for the Quirky Update
--===== Verify the the running total worked on the 
     -- TransactionDetail table
    USE TEMPDB --Takes 10 seconds on my machine
   EXEC dbo.Verify
GO
--CODE FROM FIGURE 21 - Ordered Update Attempt Used CTE
/*************************************************************************************
 Pseduo-cursor Running Total update using an "ordered" CTE that's not in the same 
 order as the clustered index.
*************************************************************************************/
--===== Reset the running total columns
   EXEC dbo.ResetTestTable

--===== Supress the auto-display of rowcounts for speed an appearance
   SET NOCOUNT ON

--===== Reset the running total/count columns
   EXEC dbo.ResetTestTable --This isn't actually necessary in "real" code

--===== Declare the working variables
DECLARE @NCID         INT,
        @AccountRunningTotal MONEY,
        @AccountRunningCount INT

 SELECT @AccountRunningTotal = 0,
        @AccountRunningCount = 0

--===== Update the running total using multipart updates
     -- applied to an "ordered" CTE.
;WITH cteOrdered AS
(
 SELECT TOP 2147483648
        NCID,
        Amount,
        AccountRunningTotal,
        AccountRunningCount 
   FROM dbo.TransactionDetail
  ORDER BY NCID DESC --Don't forget... reverse order here
)
 UPDATE cteOrdered
    SET @AccountRunningTotal = AccountRunningTotal = @AccountRunningTotal + Amount,
        @AccountRunningCount = AccountRunningCount = @AccountRunningCount +1,
        @NCID = NCID 
   FROM cteOrdered WITH (TABLOCKX)
 OPTION (MAXDOP 1)
GO
--CODE FROM FIGURE 22 - Simple Verification by NCID (it failed)
--===== Show that the "ORDER BY" method didn't work.
     -- The running balance column makes no sense in this order.
     -- Don’t forget... it’s in reverse order
 SELECT TOP 100 * 
   FROM dbo.TransactionDetail
  ORDER BY NCID DESC
GO
--CODE FROM FIGURE 24 - Simple Verification by Clustered Index (it passed)
--===== Show that the "Quirky Update" overrode the ORDER BY
     -- and still performed the update in clustered index order.
 SELECT TOP 100 * 
   FROM dbo.TransactionDetail
  ORDER BY AccountID, Date, TransactionDetailID
GO
--CODE FROM FIGURE 25 - 3 Part Set Statement Sometimes "Forgets"
--===== Create a 4 row test table variable and preset all the rows to zero.
     -- It also creates an "Expected" column which should be the value of
     -- the SomeInt column (starts a 3, counts by 3) when we're done.
DECLARE @OMG TABLE 
        (RowNum INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, SomeInt INT, Expected INT)
 INSERT INTO @OMG (SomeInt, Expected) 
 SELECT 0,3 UNION ALL SELECT 0,6 UNION ALL SELECT 0,9 UNION ALL SELECT 0,12

--===== Create a variable to hold a number 
     -- and preset it to some known value
DECLARE @N INT, @Anchor INT
 SELECT @N = 0 

--===== Do a 3 part "Quirky Update" that is supposed to count by 3's (1+2)
     -- but loses it's mind instead.  It only does the @N + 2 for the 
     -- first row.
 UPDATE @OMG
    SET @N      = @N + 1,           --Adds 1 to N 
        @N      = SomeInt = @N + 2, --"Forgets" to do @N + 2 after first row
        @Anchor = RowNum
   FROM @OMG --WITH (TABLOCKX) --Can't be used on a table variable
 OPTION (MAXDOP 1)

--===== Display the result. Should start at 3 and count by 3's.
     -- But it doesn't!!! It starts at 3 and counts by 1's.  It didn't do
     -- the @N + 2 for anything except the first row.
 SELECT * FROM @OMG
GO 
--CODE FROM FIGURE 27 - 2 Part Set Statements Always Work as Expected
--===== Create a 4 row test table variable and preset all the rows to zero.
     -- It also creates an "Expected" column which should be the value of
     -- the SomeInt column (starts a 3, counts by 3) when we're done.
DECLARE @OMG TABLE 
       (RowNum INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, SomeInt INT, Expected INT)
 INSERT INTO @OMG (SomeInt, Expected) 
 SELECT 0,3 UNION ALL SELECT 0,6 UNION ALL SELECT 0,9 UNION ALL SELECT 0,12

--===== Create a variable to hold a number 
     -- and preset it to some known value
DECLARE @N INT, @Anchor INT
 SELECT @N = 0 

--===== Do a "Quirky Update" with only 2 part SET statements
     -- to overcome the problem.
 UPDATE @OMG
    SET @N      = @N + 1, --Adds 1 to N (works every time)
        @N      = @N + 2, --Adds another 2 to N (works every time)
        SomeInt = @N,     --Updates SomeInt with N
        @Anchor = RowNum
   FROM @OMG --WITH (TABLOCKX) --Can't be used on a table variable
 OPTION (MAXDOP 1)

--===== Display the result. Should start at 3 and count by 3's.
     -- This time it worked.
 SELECT * FROM @OMG
GO
--CODE FROM FIGURE 28 - The correct way to count by 3
--===== Create a 4 row test table variable and preset all the rows to zero.
     -- It also creates an "Expected" column which should be the value of
     -- the SomeInt column (starts a 3, counts by 3) when we're done.
DECLARE @OMG TABLE 
       (RowNum INT IDENTITY(1,1) PRIMARY KEY CLUSTERED, SomeInt INT, Expected INT)
 INSERT INTO @OMG (SomeInt, Expected) 
 SELECT 0,3 UNION ALL SELECT 0,6 UNION ALL SELECT 0,9 UNION ALL SELECT 0,12

--===== Create a variable to hold a number 
     -- and preset it to some known value
DECLARE @N INT, @Anchor INT
 SELECT @N = 0 

--===== Do a "Quirky Update" with the 3 part SET statement done
     -- the right way.
 UPDATE @OMG
    SET @N = SomeInt = @N + 3, --Adds 3 to n and updates SomeInt with N
        @Anchor = RowNum
   FROM @OMG --WITH (TABLOCKX) --Can't be used on a table variable
 OPTION (MAXDOP 1)

--===== Display the result. Should start at 3 and count by 3's.
     -- This time it worked.
 SELECT * FROM @OMG
GO


