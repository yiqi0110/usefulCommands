SET NOCOUNT ON
DECLARE @Schema NVARCHAR(100) = 'data'
DECLARE @Table NVARCHAR(100) = 'user_defined_standard_time'
DECLARE @sql NVARCHAR(MAX) =''
IF OBJECT_ID ('tempdb..#Nulls') IS NOT NULL DROP TABLE #Nulls

CREATE TABLE #Nulls ( 
ColumnName sysname, 
NullCount int, 
BlankStringCount int,
DistinctCount int,
)

SELECT @sql += 'SELECT '''+COLUMN_NAME+''' AS ColumnName,
	SUM(CASE WHEN '+COLUMN_NAME+' IS NULL THEN 1 ELSE 0 END) NullCount,
	SUM(CASE WHEN LEN('+COLUMN_NAME+') = 0 THEN 1 ELSE 0 END) BlankStringCount,
	COUNT( DISTINCT '+COLUMN_NAME+') DistinctCount
	FROM '+QUOTENAME(TABLE_SCHEMA)+'.'+QUOTENAME(TABLE_NAME)+';'+ CHAR(10)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @Schema
AND TABLE_NAME = @Table

INSERT INTO #Nulls 
EXEC sp_executesql @sql

SELECT * 
FROM #Nulls
