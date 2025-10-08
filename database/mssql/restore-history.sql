SELECT r.destination_database_name, r.user_name, r.restore_date, r.replace, b.backup_start_date, b.backup_finish_date, b.backup_set_id, b.type, m.physical_device_name
FROM msdb.dbo.restorehistory r
INNER JOIN msdb.dbo.backupset b ON r.backup_set_id = b.backup_set_id
INNER JOIN msdb.dbo.backupmediafamily m ON b.media_set_id = m.media_set_id
ORDER BY r.restore_date DESC;