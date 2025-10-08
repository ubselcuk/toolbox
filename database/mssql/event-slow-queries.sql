-- Ensure the target folder exists and SQL Server has write permissions to it
-- Replace 'C:\SQLTrace' with your desired folder path
-- Windows:
    -- mkdir C:\SQLTrace
    -- icacls "C:\SQLTrace" /grant "NT SERVICE\MSSQLSERVER:(OI)(CI)F"
-- Linux & Docker:
    -- docker exec -it <container_name_or_id> bash
    -- mkdir -p /var/opt/mssql/xe_logs
    -- chown mssql:mssql /var/opt/mssql/xe_logs
    -- chmod 770 /var/opt/mssql/xe_logs

-- Ensure SQL Server has write permissions to the folder

-- If event session already exists, drop it
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'Slow_Queries')
BEGIN
    DROP EVENT SESSION [Slow_Queries] ON SERVER;
END;

-- Create event session to capture slow queries (duration > 10 seconds)
CREATE EVENT SESSION [Slow_Queries] ON SERVER
ADD EVENT sqlserver.rpc_completed(
    ACTION(sqlserver.sql_text, sqlserver.session_id)
    WHERE duration > 10000000), -- 10 seconds
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.sql_text, sqlserver.session_id)
    WHERE duration > 10000000)
ADD TARGET package0.event_file (
    SET filename = 'C:\SQLTrace\SlowQueries.xel', -- or /var/opt/mssql/xe_logs/SlowQueries.xel
        max_file_size = 50, -- in MB
        max_rollover_files = 5
)
WITH (STARTUP_STATE = ON);

-- Start the event session
ALTER EVENT SESSION [Slow_Queries] ON SERVER STATE = START;