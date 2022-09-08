declare @sname varchar(500) = 'swims';
declare @tname varchar(500) = 'PersonOrgGroup';

select distinct
	OBJECT_SCHEMA_NAME(FKC.parent_object_id) as [SchemaName]
	,OBJECT_NAME(FKC.parent_object_id) as [TableName]
	,SC_P.name as [ParentColumn]
	,OBJECT_SCHEMA_NAME(SO_R.object_id) as [ReferencedSchema]
	,SO_R.name as [ReferencedTable]
	,SC_R.name as [ReferencedColumn]
from sys.foreign_key_columns FKC
	inner join sys.objects SO_P 
		on SO_P.object_id = FKC.parent_object_id
	inner join sys.columns SC_P 
		on (SC_P.object_id = FKC.parent_object_id) AND (SC_P.column_id = FKC.parent_column_id)
	inner join sys.objects SO_R 
		on SO_R.object_id = FKC.referenced_object_id
	inner join sys.columns SC_R 
		on (SC_R.object_id = FKC.referenced_object_id) AND (SC_R.column_id = FKC.referenced_column_id)
	INNER JOIN sys.schemas SCH_P 
		ON SO_P.schema_id = SCH_P.SCHEMA_ID
	INNER JOIN sys.schemas SCH_R 
		ON SO_R.schema_id = SCH_R.schema_id
	INNER JOIN sys.objects foreignKey 
		ON foreignKey.object_id = FKC.constraint_object_id
where
		(OBJECT_SCHEMA_NAME(FKC.parent_object_id) = @sname
		and OBJECT_NAME(FKC.parent_object_id) = @tname)
		or (OBJECT_SCHEMA_NAME(SO_R.object_id) = @sname
		and SO_R.name = @tname);