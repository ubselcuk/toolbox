SELECT
  SERVERPROPERTY('Edition')        AS Edition,
  SERVERPROPERTY('ProductVersion') AS ProductVersion,
  SERVERPROPERTY('ProductLevel')   AS ProductLevel,
  SERVERPROPERTY('EngineEdition')  AS EngineEdition,
  @@VERSION                        AS Version;