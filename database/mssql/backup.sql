DECLARE @DatabaseName NVARCHAR(256)
DECLARE @BackupFile NVARCHAR(512)
DECLARE @LogBackupFile NVARCHAR(512)
DECLARE @Timestamp NVARCHAR(20)
DECLARE @SQL NVARCHAR(MAX)

-- Generate timestamp (yyyyMMdd_HHmm)
SET @Timestamp = CONVERT(varchar(8), GETDATE(), 112) + '_' + REPLACE(CONVERT(varchar(5), GETDATE(), 108), ':', '')

-- Cursor for user databases
DECLARE db_cursor CURSOR FOR
SELECT name FROM sys.databases WHERE name NOT IN ('master','model','msdb','tempdb')

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN
    -- File paths inside container
    SET @BackupFile = '/var/opt/mssql/backups/' + @DatabaseName + '_Full_' + @Timestamp + '.bak'
    SET @LogBackupFile = '/var/opt/mssql/backups/' + @DatabaseName + '_Log_' + @Timestamp + '.trn'

    -- Full Backup
    SET @SQL = 'BACKUP DATABASE [' + @DatabaseName + '] TO DISK = N''' + @BackupFile + ''' WITH INIT, SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10'
    EXEC (@SQL)

    -- Log Backup (skip if recovery model is SIMPLE)
    IF (SELECT recovery_model_desc FROM sys.databases WHERE name = @DatabaseName) <> 'SIMPLE'
    BEGIN
        SET @SQL = 'BACKUP LOG [' + @DatabaseName + '] TO DISK = N''' + @LogBackupFile + ''' WITH INIT, SKIP, NOREWIND, NOUNLOAD, COMPRESSION, STATS = 10'
        EXEC (@SQL)
    END

    FETCH NEXT FROM db_cursor INTO @DatabaseName
END

CLOSE db_cursor
DEALLOCATE db_cursor

PRINT 'Backup completed successfully for all user databases.'