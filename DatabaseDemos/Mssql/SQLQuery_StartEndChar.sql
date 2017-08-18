



declare @string varchar(max)
declare @delimiter char(1)
select @string = 'accountant|account manager|account payable specialist|benefits specialist|database administrator|quality assurance engineer' 
select @delimiter = '|';

with Delimitered_CTE (starting_character, ending_character, occurence)
as
(
     select -- set starting character to 1:
     starting_character = 1, ending_character = 
     cast(CHARINDEX(@delimiter,@string + @delimiter)as int)
     ,1 as occurence
union all
     select -- set starting character to 1 after the ending character:     
     starting_character = ending_character + 1 ,
     cast(charindex(@delimiter,@string + @delimiter,ending_character + 1) as int),
     occurence + 1
     from Delimitered_CTE
     where CHARINDEX(@delimiter,@string + @delimiter, ending_character +1 ) <> 0
)
select *,SUBSTRING(@string,starting_character,ending_character-starting_character) as String_Values
from Delimitered_CTE
option (maxrecursion 20)

