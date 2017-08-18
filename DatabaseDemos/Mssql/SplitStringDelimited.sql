
use staging

DECLARE @string varchar(MAX) = '10||3112||||aaaa||'
DECLARE @s varchar(8000) = 'the quick brown dog jumped over the lazy fox';
DECLARE @del char(2) = '||'

;with Parser(pos, nex) as (
	select cast(1 as bigint) as pos, charindex(@del, @string) as nex
	union all
	select nex + len(@del) as pos, charindex(@del, @string, nex + 1) as nex
	from Parser where nex > 0
)
select substring(@string, pos, nex - pos) 
from Parser
where nex > pos

DECLARE @Char VARCHAR(MAX) = '10||3112||||aaaa||'
DECLARE @Separador CHAR(2) = '||'

;WITH Entrada AS(
    SELECT
        CAST(1 AS Int) As Inicio,
        CHARINDEX(@Separador, @Char) As Fim
    UNION ALL
    SELECT
        CAST(Fim + LEN(@Separador) AS Int) As Inicio,
        CHARINDEX(@Separador, @Char, Fim + 1) As Fim
    FROM Entrada
    WHERE CHARINDEX(@Separador, @Char, Fim + 1) > 0
)
SELECT 
    SUBSTRING(@Char, Inicio, Fim - Inicio)
FROM Entrada
WHERE (Fim - Inicio) > 0
