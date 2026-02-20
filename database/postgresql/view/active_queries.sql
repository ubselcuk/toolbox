CREATE OR REPLACE VIEW active_queries AS
SELECT
    pid,
    usename AS user,
    now() - query_start AS duration,
    wait_event_type || ': ' || wait_event AS wait_info,
    query
FROM pg_stat_activity
WHERE state = 'active'
  AND pid <> pg_backend_pid() -- Do not include the current session
ORDER BY duration DESC;

COMMENT ON VIEW active_queries IS 'Lists currently active queries, their duration, and wait events to identify performance bottlenecks.';