/*
http://weblogs.sqlteam.com/jeffs/archive/2007/04/03/Conditional-Joins.aspx
*/

USE Dev

DECLARE @test AS TABLE (
	color xml
)

INSERT @test (color)
VALUES ('<root><backgroundcolor>FF8DB3E3</backgroundcolor></root>')
		,('<root><backgroundcolor>FFE46C0A</backgroundcolor></root>')
		,('<root><backgroundcolor>FF595959</backgroundcolor></root>')

SELECT color.value('(root/backgroundcolor)[1]', 'nvarchar(8)') FROM @test

