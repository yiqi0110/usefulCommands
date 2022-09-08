
declare @schemaName nvarchar(50) = 'fact'
declare @tableName nvarchar(300) = 'ImxSummary'

IF OBJECT_ID(N'tempdb..#constraintGen') IS NOT NULL
BEGIN
	DROP TABLE #constraintGen
END;
IF OBJECT_ID(N'tempdb..#temp') IS NOT NULL
BEGIN
	DROP TABLE #temp
END;

select distinct
	OBJECT_SCHEMA_NAME(FKC.parent_object_id) as [SchemaName]
	,OBJECT_NAME(FKC.parent_object_id) as [TableName]
	,SC_P.name as [ParentColumn]
	,OBJECT_SCHEMA_NAME(SO_R.object_id) as [ReferencedSchema]
	,SO_R.name as [ReferencedTable]
	,SC_R.name as [ReferencedColumn]
	,'ALTER TABLE ['+SCH_P.name+'].['+SO_P.name+'] DROP CONSTRAINT ['+foreignKey.name+']' AS [DropCommand]
	,'ALTER TABLE [' + SCH_P.name + '].[' + SO_P.name + '] 
	WITH NOCHECK ADD CONSTRAINT [' + foreignKey.name +'] FOREIGN KEY (' + SC_P.name +
	') REFERENCES [' + SCH_R.name + '].[' + SO_R.name + '](' + SC_R.name + ')' AS [CreateCommand]
	,'ALTER TABLE [' + SCH_P.name + '].[' + SO_P.name + '] 
		CHECK CONSTRAINT [' + foreignKey.name +']' AS [CheckCommand]
into #constraintGen
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
	where (OBJECT_SCHEMA_NAME(FKC.parent_object_id) = @schemaName
		and OBJECT_NAME(FKC.parent_object_id) = @tableName)
		or (OBJECT_SCHEMA_NAME(SO_R.object_id) = @schemaName
		and SO_R.name = @tableName);

SELECT
	ROW_NUMBER() OVER (order by cg.SchemaName) as [rowCount]
	,cg.*
INTO #temp
FROM #constraintGen cg

-- drop constraints
DECLARE @tempCount INT = (SELECT COUNT(*) FROM #temp);

DECLARE @dropCount INT = 1;
WHILE (@dropCount <= @tempCount)
begin
	DECLARE @dropCommand NVARCHAR(MAX) = (select top 1 [DropCommand] from #temp where [rowCount] = @dropCount);
	DECLARE @dropSql NVARCHAR(MAX) = N''+@dropCommand+'';

	exec(@dropSql)

	SET @dropCount = @dropCount + 1;
end;

-- truncate table
	DECLARE @truncateSql NVARCHAR(MAX) = N'truncate table '+@schemaName+'.'+@tableName;
	DECLARE @reseedSql NVARCHAR(100) = N'DBCC CHECKIDENT ('+@schemaName+'.'+@tableName+', RESEED, 1);';

	begin try
		exec(@truncateSql)
		exec(@reseedSql)
	end try
	begin catch
		RAISERROR (N'Failure at truncate %s %d.', -- Message text.
							 10, -- Severity,
							 1 -- State
							 )
	end catch

-- create/check constraints
DECLARE @createCount INT = 1;
WHILE (@createCount <= @tempCount)
begin
	DECLARE @createCommand NVARCHAR(MAX) = (select top 1 [CreateCommand] from #temp where [rowCount] = @createCount);
	DECLARE @checkCommand NVARCHAR(MAX) = (select top 1 [CheckCommand] from #temp where [rowCount] = @createCount);
	DECLARE @createSql NVARCHAR(MAX) = N''+@createCommand+'';
	DECLARE @checkSql NVARCHAR(MAX) = N''+@checkCommand+'';

	exec(@createSql);

	begin try
		exec(@checkSql);
	end try
	begin catch
		RAISERROR (N'Failure at create %s %d.', -- Message text.
							 10, -- Severity,
							 1 -- State
							 )
	end catch

	SET @createCount = @createCount + 1;
end;