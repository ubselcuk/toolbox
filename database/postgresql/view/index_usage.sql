CREATE OR REPLACE VIEW index_usage AS
SELECT
    t.relname AS table_name,
    i.indexrelname AS index_name,
    i.idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size
FROM pg_stat_user_indexes i
JOIN pg_class t ON t.oid = i.relid
ORDER BY i.idx_scan ASC, pg_relation_size(i.indexrelid) DESC;

COMMENT ON VIEW index_usage IS 'Identifies unused or rarely used indexes to optimize write performance.';
