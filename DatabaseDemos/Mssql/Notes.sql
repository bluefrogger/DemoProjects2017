
use this to remove any new lines in the sql cell
REPLACE(REPLACE(FieldValue, CHAR(13), ''), CHAR(10), '')
