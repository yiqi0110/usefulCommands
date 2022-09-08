SET NOCOUNT ON
DECLARE @Schema NVARCHAR(100) = 'data'
DECLARE @Table NVARCHAR(100) = 'standard'
DECLARE @sql NVARCHAR(MAX) =''
IF OBJECT_ID ('tempdb..#Nulls') IS NOT NULL DROP TABLE #Nulls

CREATE TABLE #Nulls ( 
ColumnName sysname, 
NullCount int,
PercentageNull decimal(5,2),
BlankStringCount int,
PercentageBlank decimal(5,2),
DistinctCount int,
PercentageDistinct decimal(5,2)
)

SELECT @sql += 'SELECT '''+COLUMN_NAME+''' AS ColumnName,
	SUM(CASE WHEN '+COLUMN_NAME+' IS NULL THEN 1 ELSE 0 END) NullCount,
	(SUM(CASE WHEN '+COLUMN_NAME+' IS NULL THEN 1 ELSE 0 END)*100.00/
		SUM(COUNT(*)) OVER()) PercentageNull,
	SUM(CASE WHEN LEN('+COLUMN_NAME+') = 0 THEN 1 ELSE 0 END) BlankStringCount,
	(SUM(CASE WHEN LEN('+COLUMN_NAME+') = 0 THEN 1 ELSE 0 END)*100.00/
		SUM(COUNT(*)) OVER()) PercentageBlank,
	COUNT( DISTINCT '+COLUMN_NAME+') DistinctCount,
	(COUNT( DISTINCT '+COLUMN_NAME+')*100.00/
		SUM(COUNT(*)) OVER()) PercentageDistinct
	FROM '+QUOTENAME(TABLE_SCHEMA)+'.'+QUOTENAME(TABLE_NAME)+';'+ CHAR(10)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @Schema
AND TABLE_NAME = @Table

INSERT INTO #Nulls 
EXEC sp_executesql @sql

SELECT * 
FROM #Nulls
