use staging

;with Tally(nb) as
(
	select 0
	union all
	select row_number() over (order by (select null))
	from (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as aa(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as bb(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as cc(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as dd(nb)
	cross join (values (0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) as ee(nb)
)
merge dbo.Tally as tar
using (
select nb from Tally
	) as src(nb)
on tar.nb = src.nb
when not matched by target then
	insert (nb)
	values (src.nb);

SET NOCOUNT ON;
IF OBJECT_ID('RoomRent') IS NULL
BEGIN
       CREATE TABLE dbo.RoomRent (
              RoomName VARCHAR(50)
              ,ReserveDate DATETIME);
 
       INSERT INTO RoomRent VALUES ('QuarterMaster','3/15/2011')
       INSERT INTO RoomRent VALUES ('QuarterMaster','3/17/2011')
       INSERT INTO RoomRent VALUES ('Commencement','3/14/2011')
END
/*
select * from dbo.RoomRent
select * from dbo.Tally
*/
declare @begindate datetime = '3/10/2011'
declare @enddate datetime = '3/20/2011'

select RoomName, ReserveDate, tt.CheckDate from dbo.RoomRent as rr
right join (
	select dateadd(dd, nb - 1, @begindate) as CheckDate
	from dbo.Tally 
	where nb <= datediff(dd, @begindate, @enddate) + 1
)as tt
on rr.ReserveDate = tt.CheckDate

SET NOCOUNT ON;
IF OBJECT_ID('Event') IS NULL
BEGIN
       CREATE TABLE Event (
              ID INT IDENTITY
              ,ImpactedIndividuals VARCHAR(150)
              ,EventDate DATETIME
              ,EventComment VARCHAR(MAX));
       INSERT INTO Event (ImpactedIndividuals, EventDate, EventComment)
         VALUES ('Stan Smith;Doris Russell;Don Catalina','5/15/2010','Received CPR training');
       INSERT INTO Event (ImpactedIndividuals, EventDate, EventComment)
         VALUES ('Ryan Jone;Sam Hayden','5/18/2010','Attended SSIS presentation');
       INSERT INTO Event (ImpactedIndividuals, EventDate, EventComment)
         VALUES ('Dan Johnson','5/22/2010','Received 10 year Service Award');
END

;with Parser as(
	select ImpactedIndividuals
		, nb as beg
		, charindex(';', ImpactedIndividuals + ';', nb) as fin
	from dbo.Event cross join dbo.Tally
	where nb < len(ImpactedIndividuals)
		and substring(';' + ImpactedIndividuals, nb, 1) = ';'
)
select ImpactedIndividuals
	, beg
	, fin
	, substring(ImpactedIndividuals, beg, fin-beg)
from Parser

use staging
--Split Comma Seperated values
DECLARE @Str varchar(1000) = 'Hari,Jon,Ravi,Vijay,Peter,Max'
DECLARE @Delimiter char(1) = ','

-- Append delimiter at the beginning and end
SET @Str = @Delimiter + @Str + @Delimiter

SELECT SUBSTRING(@Str, nb + 1, CHARINDEX(@Delimiter, @Str, nb + 1) - nb - 1) as SplitedString
FROM dbo.Tally  
WHERE nb < LEN(@Str) 
AND SUBSTRING(@Str, nb, 1) = @Delimiter

go

use staging
CREATE PROC dbo.uspLogError(
	@Handle         UNIQUEIDENTIFIER
  , @ErrorNumber    INT
  , @ErrorSeverity  INT
  , @ErrorState     INT
  , @ErrorProcedure SYSNAME
  , @ErrorLine      INT
  , @ErrorMessage   NVARCHAR(4000))
AS
BEGIN
	BEGIN TRY
		INSERT dbo.LogError (Handle, ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage)
		VALUES (@Handle, @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine, @ErrorMessage);
	END TRY
	BEGIN CATCH
		EXEC xp_logevent @ErrorNumber, @ErrorMessage;
	END CATCH;
END;

use staging
select nb, char(nb) as ch into dbo.AsciiTable from dbo.tally where nb <= 127
select * from dbo.AsciiTable

declare @s nvarchar(1000) = '123a456b789c0d'
;with Parser(ch) as(
	select substring(@s, nb, 1)
	from dbo.Tally as ta
	where nb < len(@s)
)
select '' + pa.ch 
from Parser as pa
left join dbo.AsciiTable as ac
	on pa.ch = ac.ch
where ac.nb >= 48 and ac.nb <= 57
for xml path('')

