
USE AWLT2011

use master
select * from sys.xml_schema_collections
select * from sys.xml_schema_namespaces
select * from sys.xml_schema_elements
select * from sys.xml_schema_attributes
select * from sys.schemas
select XML_SCHEMA_NAMESPACE('SalesLT', 'ProductDescriptionSchemaCollection')
