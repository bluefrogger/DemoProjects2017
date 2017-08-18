/*
http://blog.sqlauthority.com/2015/06/24/sql-server-fix-export-error-microsoft-ace-oledb-12-0-provider-is-not-registered-on-the-local-machine/
*/

USE master
EXECUTE MASTER.dbo.xp_enum_oledb_providers

