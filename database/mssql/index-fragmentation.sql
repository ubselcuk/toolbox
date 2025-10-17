USE [YOUR_DB_NAME];  -- Check fragmentation in this database

SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM sys.dm_db_index_physical_stats (
    DB_ID(),          -- Current database
    NULL,             -- All tables
    NULL,             -- All indexes
    NULL,             -- All levels
    'LIMITED'         -- Fast, approximate results - SAMPLED - DETAILED
) AS ips
JOIN sys.indexes AS i
    ON ips.object_id = i.object_id
    AND ips.index_id = i.index_id
WHERE i.type > 0      -- Exclude heaps, only clustered or nonclustered indexes
ORDER BY ips.avg_fragmentation_in_percent DESC;