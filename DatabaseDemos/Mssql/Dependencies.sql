

SELECT OBJECT_NAME(fk.parent_object_id)
	, OBJECT_NAME(fk.referenced_object_id)
FROM sys.foreign_keys AS fk WHERE name = 'FK_sh_PhysicianServices_sh_Physicians'

/*
	http://stackoverflow.com/questions/11041797/tsql-cte-how-to-avoid-circular-traversal
	http://sqlblog.com/blogs/jamie_thomson/archive/2009/09/08/deriving-a-list-of-tables-in-dependency-order.aspx
*/

SELECT 
    s.name as SchemaName,
    t.name as TableName,
    tc.name as ColumnName,
    ic.key_ordinal as KeyOrderNr
from 
    sys.schemas s 
    inner join sys.tables t   on s.schema_id=t.schema_id
    inner join sys.indexes i  on t.object_id=i.object_id
    inner join sys.index_columns ic on i.object_id=ic.object_id 
                                   and i.index_id=ic.index_id
    inner join sys.columns tc on ic.object_id=tc.object_id 
                             and ic.column_id=tc.column_id
where i.is_primary_key=1 
order by t.name, ic.key_ordinal;


USE ElevateDev

SELECT * FROM sys.foreign_keys AS fk WHERE name = 'FK_Schedule_Encounters_Schedule_Appointments';

USE [coreDev.SolutaHealth.com];

WITH fk_tables
AS (
	SELECT
		s1.name AS from_schema
		, o1.name AS from_table
		, s2.name AS to_schema
		, o2.name AS to_table
	FROM sys.foreign_keys fk
	JOIN sys.objects o1 ON fk.parent_object_id = o1.object_id
	JOIN sys.schemas s1 ON o1.schema_id = s1.schema_id
	JOIN sys.objects o2 ON fk.referenced_object_id = o2.object_id
	JOIN sys.schemas s2 ON o2.schema_id = s2.schema_id
	/*For the purposes of finding dependency hierarchy we're not worried about self-referencing tables*/
	WHERE NOT (s1.name = s2.name AND o1.name = o2.name)
		AND o1.name IN ('sh_Employers','sh_PracticeGroups','sh_Practices','sh_PracticeAccounts','sh_PracticeContacts','sh_X12Entities_Practices_X12Entities','sh_EmployerPractices','sh_EmployerDivisions','sh_Patients','sh_PatientIdentities','sh_PatientContacts','sh_PatientContacts','sh_Physicians','sh_PhysicianPractices','sh_PhysicianContacts','sa_Resources','sh_SubjectiveRFVPreferences','sh_SubjectiveRFVs','sa_Appointments','sh_Encounters'
				,'Employers_Main', 'Practices_Groups', 'Practices_Clinics', 'Practices_ClinicAccounts', 'Practices_ClinicAddresses', 'Practices_X12Entities', 'Employers_Clinics', 'Employers_Divisions', 'Patients_Main', 'Patients_Charts', 'Patients_Contacts', 'Patients_Addresses', 'Providers_Main', 'Providers_Clinics', 'Providers_Addresses', 'Schedule_AppointmentResources', 'RFV_Categories', 'RFV_RFVMain', 'Schedule_Appointments', 'Schedule_Encounters')
	)
, ordered_tables
AS (
	SELECT
		s.name AS schemaName
		, t.name AS tableName
		, 0 AS Level
		, CAST(s.name + '.' + t.name AS VARCHAR(1000)) AS Sentinel
    FROM (
		SELECT * FROM sys.tables WHERE name <> 'sysdiagrams'
	) AS t
	JOIN sys.schemas s ON t.schema_id = s.schema_id
	LEFT JOIN fk_tables fk 
		ON s.name = fk.from_schema
        AND t.name = fk.from_table
    WHERE fk.from_schema IS NULL
    UNION ALL
    SELECT fk.from_schema
		, fk.from_table
		, ot.Level + 1
		, CAST(Sentinel + '|' + fk.from_schema + '.' + fk.from_table AS VARCHAR(1000))
    FROM fk_tables fk
    JOIN ordered_tables AS ot
		ON ot.schemaName = fk.to_schema
		AND ot.tableName = fk.to_table
	WHERE charindex(fk.from_schema + '.' + fk.from_table, Sentinel) = 0
)
SELECT DISTINCT
	--ROW_NUMBER() OVER (ORDER BY level, mx.schemaName, mx.tableName)
	--ot.schemaName
	 ot.tableName
	, ot.Level
FROM ordered_tables AS ot
JOIN (
	SELECT
		ot2.schemaName
		, ot2.tableName
		, MAX(ot2.Level) maxLevel
	FROM ordered_tables AS ot2
	GROUP BY ot2.schemaName
		, ot2.tableName
) AS mx 
	ON ot.schemaName = mx.schemaName
	AND ot.tableName = mx.tableName
	AND ot.Level = mx.maxLevel
WHERE ot.tableName IN ('sh_Employers','sh_PracticeGroups','sh_Practices','sh_PracticeAccounts','sh_PracticeContacts','sh_X12Entities_Practices_X12Entities','sh_EmployerPractices','sh_EmployerDivisions','sh_Patients','sh_PatientIdentities','sh_PatientContacts','sh_PatientContacts','sh_Physicians','sh_PhysicianPractices','sh_PhysicianContacts','sa_Resources','sh_SubjectiveRFVPreferences','sh_SubjectiveRFVs','sa_Appointments','sh_Encounters'
		,'Employers_Main', 'Practices_Groups', 'Practices_Clinics', 'Practices_ClinicAccounts', 'Practices_ClinicAddresses', 'Practices_X12Entities', 'Employers_Clinics', 'Employers_Divisions', 'Patients_Main', 'Patients_Charts', 'Patients_Contacts', 'Patients_Addresses', 'Providers_Main', 'Providers_Clinics', 'Providers_Addresses', 'Schedule_AppointmentResources', 'RFV_Categories', 'RFV_RFVMain', 'Schedule_Appointments', 'Schedule_Encounters')
ORDER BY level, ot.tableName
--OPTION (MAXRECURSION 200);


DECLARE @MyTable TABLE(Parent CHAR(1), Child CHAR(1));

INSERT @MyTable VALUES('A', 'B');
INSERT @MyTable VALUES('B', 'C');
INSERT @MyTable VALUES('C', 'D');
INSERT @MyTable VALUES('D', 'A');

; WITH CTE (Parent, Child, Sentinel) AS (
    SELECT  Parent, Child, Sentinel = CAST(Parent AS VARCHAR(MAX))
    FROM    @MyTable
    WHERE   Parent = 'A'
    UNION ALL
    SELECT  CTE.Child, t.Child, Sentinel + '|' + CTE.Child
    FROM    CTE
    JOIN    @MyTable AS t ON t.Parent = CTE.Child
    WHERE CHARINDEX(CTE.Child,Sentinel) = 0
)
SELECT * FROM CTE;


WITH
  TablesCTE(TableName, TableID, Ordinal) AS
  (
  SELECT 
    OBJECT_SCHEMA_NAME(so.object_id) +'.'+ OBJECT_NAME(so.object_id) AS TableName,
    so.object_id AS TableID,
    0 AS Ordinal
  FROM sys.objects so INNER JOIN sys.all_columns ac ON so.object_id = ac.object_id
  WHERE
    so.type = 'U'
  AND
    ac.is_identity = 1
  UNION ALL
  SELECT 
    OBJECT_SCHEMA_NAME(so.id) +'.'+ OBJECT_NAME(so.id) AS TableName,
    so.id AS TableID,
    tt.Ordinal + 1 AS Ordinal
  FROM 
    dbo.sysobjects so 
    INNER JOIN sys.all_columns ac ON so.ID = ac.object_id
    INNER JOIN sys.foreign_keys f 
      ON (f.parent_object_id = so.id AND f.parent_object_id != f.referenced_object_id)
    INNER JOIN TablesCTE tt ON f.referenced_object_id = tt.TableID
  WHERE
    so.type = 'U'
  AND
    ac.is_rowguidcol = 1
)  
SELECT DISTINCT 
  t.Ordinal,
  t.TableName
  FROM TablesCTE t
  INNER JOIN 
    (
    SELECT 
      TableName as TableName,
      Max (Ordinal) as Ordinal
    FROM TablesCTE
    GROUP BY TableName
    ) tt ON (t.TableName = tt.TableName  AND t.Ordinal = tt.Ordinal)
ORDER BY t.Ordinal, t.TableName;

