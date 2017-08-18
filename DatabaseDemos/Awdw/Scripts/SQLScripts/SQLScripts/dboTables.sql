/*
CREATE TABLE dbo.LogActivity
(
	Id            INT IDENTITY(1,1)
   ,Handle        UNIQUEIDENTIFIER
   ,ProcedureName SYSNAME
   ,LoginName     NVARCHAR(512)
   ,UserName      NVARCHAR(512)
   ,LogDate       DATE
   ,LogTime       TIME
   ,LogStatus     INT
);

CREATE TABLE dbo.Settings
(
	Id           INT IDENTITY(1,1)
   ,Name         NVARCHAR(512)
   ,Detail       NVARCHAR(512)
   ,Value        NVARCHAR(512)
   ,ValueDefault NVARCHAR(512)
   ,ValueStatus  INT
);

CREATE TABLE dbo.Statuses
(
	Id     INT IDENTITY(1,1)
   ,Name   NVARCHAR(512)
   ,Detail NVARCHAR(512)
);

CREATE TABLE dbo.LogError
(
	Id             INT IDENTITY(1,1)
   ,Handle         UNIQUEIDENTIFIER
   ,ErrorNumber    INT
   ,ErrorSeverity  INT
   ,ErrorState     INT
   ,ErrorProcedure NVARCHAR(128)
   ,ErrorLine      INT
   ,ErrorMessage   NVARCHAR(4000)
);
*/
use staging
use awlt2011 --use openquery for linked server

:setvar SourceServer binaryrex
:setvar SourceDatabase AWLT2011
:setvar SourceSchema SalesLT

:setvar TargetDatabase Staging
:setvar TargetSchema awlt2011

;with DataTypes as
(
	select schema_name(tab.schema_id) as SchemaName, tab.name as TableName, col.name as ColumnName, typ.name as TypeName, typsys.name, typ.max_length, typ.precision, typ.scale
		, col.is_identity, col.is_nullable, col.xml_collection_id
		, object_definition(col.default_object_id) as default_value
		, col.name + ' ' + case
			when typ.name in ('nvarchar', 'nchar') then typ.name + '(' + cast(typ.max_length / 2 as varchar(100)) + ')'
			when typ.name in ('varchar', 'char') then typ.name + '(' + cast(typ.max_length as varchar(100)) + ')'
			when typ.name in ('decimal', 'numeric') then typ.name + '(' + cast(typ.precision as varchar(100)) + ',' + cast(typ.scale as varchar(100)) + ')'
			else typ.name
		end as DataType
	from $(SourceServer).$(SourceDatabase).sys.columns as col
	join $(SourceServer).$(SourceDatabase).sys.tables as tab
		on col.object_id = tab.object_id
	join $(SourceServer).$(SourceDatabase).sys.types as typ
		on col.user_type_id = typ.user_type_id
	left join $(SourceServer).$(SourceDatabase).sys.types as typsys
		on typ.system_type_id = typsys.user_type_id
	where not (tab.schema_id = 1)
)
select 'create table $(TargetSchema).' + TableName + ' ('
	+ stuff((
		select ', ' + sub.DataType
		from DataTypes as sub
		where sub.TableName = super.TableName
		for xml path('')
	), 1, 1, '')
	+ ')'
from DataTypes as super
group by SchemaName, TableName

/*
use awlt2011

select 'create xml schema collection ' + xsc.name + ' as ''' + cast(XML_SCHEMA_NAMESPACE('SalesLT', 'ProductDescriptionSchemaCollection') as varchar(max)) + '''' from sys.xml_schema_collections as xsc
where not (name = 'sys')

select 'create type ' + typ.name + ' from ' + typsys.name 
	+ case
		when typ.system_type_id = 231 then '(' + cast(typ.max_length as varchar(100)) + ')'
		else ''
	end
	,typ.*
from sys.types as typ
join sys.types as typsys
	on typ.system_type_id = typsys.user_type_id
where not (typ.system_type_id = typ.user_type_id) and not (typ.name = 'sysname')

use staging
create xml schema collection ProductDescriptionSchemaCollection as '<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:t="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain" targetNamespace="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain" elementFormDefault="qualified"><xsd:element name="Maintenance"><xsd:complexType><xsd:complexContent><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:element name="NoOfYears" type="xsd:string"/><xsd:element name="Description" type="xsd:string"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType></xsd:element><xsd:element name="Warranty"><xsd:complexType><xsd:complexContent><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:element name="WarrantyPeriod" type="xsd:string"/><xsd:element name="Description" type="xsd:string"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType></xsd:element></xsd:schema><xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:ns1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain" xmlns:t="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription" targetNamespace="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription" elementFormDefault="qualified"><xsd:import namespace="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain"/><xsd:element name="Code" type="xsd:string"/><xsd:element name="Description" type="xsd:string"/><xsd:element name="ProductDescription" type="t:ProductDescription"/><xsd:element name="Taxonomy" type="xsd:string"/><xsd:complexType name="Category"><xsd:complexContent><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:element ref="t:Taxonomy"/><xsd:element ref="t:Code"/><xsd:element ref="t:Description" minOccurs="0"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType><xsd:complexType name="Features" mixed="true"><xsd:complexContent mixed="true"><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:element ref="ns1:Warranty"/><xsd:element ref="ns1:Maintenance"/><xsd:any namespace="##other" processContents="skip" minOccurs="0" maxOccurs="unbounded"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType><xsd:complexType name="Manufacturer"><xsd:complexContent><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:element name="Name" type="xsd:string" minOccurs="0"/><xsd:element name="CopyrightURL" type="xsd:string" minOccurs="0"/><xsd:element name="Copyright" type="xsd:string" minOccurs="0"/><xsd:element name="ProductURL" type="xsd:string" minOccurs="0"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType><xsd:complexType name="Picture"><xsd:complexContent><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:element name="Name" type="xsd:string" minOccurs="0"/><xsd:element name="Angle" type="xsd:string" minOccurs="0"/><xsd:element name="Size" type="xsd:string" minOccurs="0"/><xsd:element name="ProductPhotoID" type="xsd:integer" minOccurs="0"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType><xsd:complexType name="ProductDescription"><xsd:complexContent><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:element name="Summary" type="t:Summary" minOccurs="0"/><xsd:element name="Manufacturer" type="t:Manufacturer" minOccurs="0"/><xsd:element name="Features" type="t:Features" minOccurs="0" maxOccurs="unbounded"/><xsd:element name="Picture" type="t:Picture" minOccurs="0" maxOccurs="unbounded"/><xsd:element name="Category" type="t:Category" minOccurs="0" maxOccurs="unbounded"/><xsd:element name="Specifications" type="t:Specifications" minOccurs="0" maxOccurs="unbounded"/></xsd:sequence><xsd:attribute name="ProductModelID" type="xsd:string"/><xsd:attribute name="ProductModelName" type="xsd:string"/></xsd:restriction></xsd:complexContent></xsd:complexType><xsd:complexType name="Specifications" mixed="true"><xsd:complexContent mixed="true"><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:any processContents="skip" minOccurs="0" maxOccurs="unbounded"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType><xsd:complexType name="Summary" mixed="true"><xsd:complexContent mixed="true"><xsd:restriction base="xsd:anyType"><xsd:sequence><xsd:any namespace="http://www.w3.org/1999/xhtml" processContents="skip" minOccurs="0" maxOccurs="unbounded"/></xsd:sequence></xsd:restriction></xsd:complexContent></xsd:complexType></xsd:schema>'
create type AccountNumber from nvarchar (30)
create type Flag from bit
create type NameStyle from bit
create type Name from nvarchar (100)
create type OrderNumber from nvarchar (50)
create type Phone from nvarchar (50)
*/
use awlt2011

:setvar SourceServer binaryrex
:setvar SourceDatabase AWLT2011
:setvar SourceSchema SalesLT

:setvar TargetDatabase Staging
:setvar TargetSchema awlt2011

select 'select * into $(TargetDatabase).$(TargetSchema).' + Table_Name 
	+ ' from $(SourceServer).$(SourceDatabase).' + Table_Schema + '.' + Table_Name
from $(SourceServer).$(SourceDatabase).INFORMATION_SCHEMA.TABLES
where not (Table_Schema = 'dbo') and (Table_Type = 'BASE TABLE')
