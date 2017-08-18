
/* 20150827
I just stumbled across the neatest trick I’ve seen in a while. 
IF you ever have to clean your data for dummy entries like ‘111111111’, or ‘AAAAAA’ 
(values that only have one repeating character) use this:
*/

DECLARE @sampletable TABLE (Value varchar(20))
INSERT INTO @sampletable VALUES ('1111111'),('ABCDEF'),('AAAAAAA'),('DDD'),('88888888'),('12233')

SELECT *
FROM @sampletable
WHERE REPLACE(Value, LEFT(Value,1),'') = ''
