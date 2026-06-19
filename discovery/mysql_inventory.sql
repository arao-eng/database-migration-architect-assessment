-- discovery/mysql_inventory.sql
-- Extracts metadata for migration assessment

SELECT 'TABLE' AS object_type, table_name AS object_name, table_rows AS metric_or_detail
FROM information_schema.tables 
WHERE table_schema = 'petclinic'
UNION ALL
SELECT 'VIEW', table_name, 'N/A'
FROM information_schema.views 
WHERE table_schema = 'petclinic'
UNION ALL
SELECT 'ROUTINE', routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'petclinic'
UNION ALL
SELECT 'TRIGGER', trigger_name, event_manipulation
FROM information_schema.triggers 
WHERE trigger_schema = 'petclinic'
UNION ALL
SELECT 'INDEX', index_name, table_name
FROM information_schema.statistics 
WHERE table_schema = 'petclinic'
UNION ALL
SELECT 'USER', user, host 
FROM mysql.user
WHERE user NOT IN ('mysql.session', 'mysql.sys', 'mysql.infoschema', 'root');