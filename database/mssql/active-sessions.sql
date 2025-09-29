SELECT session_id, login_name, host_name, program_name, status, cpu_time, total_elapsed_time
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;
GO