-- Read-only metadata snapshot for a local FREEPDB1 application schema.
-- Usage:
--   sql /nolog -name apex_local @local-dev/snapshot-pdb.sql APP
-- The first positional argument is the schema name. Output is written as
-- snapshot_<schema>.*.csv in the current directory. Generated snapshots are
-- local artifacts and must not be committed.

SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET HEADING ON
SET PAGESIZE 50000
SET LINESIZE 32767
SET LONG 100000
SET TRIMSPOOL ON
SET SQLFORMAT CSV
SET TERMOUT OFF
SET DEFINE ON

DEFINE app_schema = &1

PROMPT Snapshot schema: &app_schema

SPOOL snapshot_&app_schema..objects.csv
SELECT object_type, COUNT(*) AS object_count
  FROM all_objects
 WHERE owner = UPPER('&app_schema')
 GROUP BY object_type
 ORDER BY object_type;
SPOOL OFF

SPOOL snapshot_&app_schema..invalid.csv
SELECT owner, object_name, object_type, status, last_ddl_time
  FROM all_objects
 WHERE owner = UPPER('&app_schema')
   AND status <> 'VALID'
 ORDER BY object_type, object_name;
SPOOL OFF

SPOOL snapshot_&app_schema..tables_without_pk.csv
SELECT t.owner, t.table_name
  FROM all_tables t
 WHERE t.owner = UPPER('&app_schema')
   AND NOT EXISTS (
       SELECT 1
         FROM all_constraints c
        WHERE c.owner = t.owner
          AND c.table_name = t.table_name
          AND c.constraint_type = 'P'
   )
 ORDER BY t.table_name;
SPOOL OFF

SPOOL snapshot_&app_schema..columns.csv
SELECT owner, table_name, column_id, column_name, data_type,
       data_length, data_precision, data_scale, nullable, data_default
  FROM all_tab_columns
 WHERE owner = UPPER('&app_schema')
 ORDER BY table_name, column_id;
SPOOL OFF

SPOOL snapshot_&app_schema..constraints.csv
SELECT owner, table_name, constraint_name, constraint_type, status,
       validated, search_condition, r_constraint_name, delete_rule, last_change
  FROM all_constraints
 WHERE owner = UPPER('&app_schema')
 ORDER BY table_name, constraint_type, constraint_name;
SPOOL OFF

SPOOL snapshot_&app_schema..indexes.csv
SELECT owner, table_name, index_name, index_type, uniqueness,
       status, visibility, last_analyzed
  FROM all_indexes
 WHERE table_owner = UPPER('&app_schema')
    OR owner = UPPER('&app_schema')
 ORDER BY table_name, index_name;
SPOOL OFF

SPOOL snapshot_&app_schema..grants.csv
SELECT grantee, owner, table_name, privilege, grantable
  FROM all_tab_privs
 WHERE owner = UPPER('&app_schema')
 ORDER BY grantee, table_name, privilege;
SPOOL OFF

SPOOL snapshot_&app_schema..synonyms.csv
SELECT owner, synonym_name, table_owner, table_name, db_link
  FROM all_synonyms
 WHERE owner = UPPER('&app_schema')
    OR table_owner = UPPER('&app_schema')
 ORDER BY owner, synonym_name;
SPOOL OFF

SPOOL snapshot_&app_schema..dependencies.csv
SELECT owner, name, type, referenced_owner, referenced_name, referenced_type, dependency_type
  FROM all_dependencies
 WHERE owner = UPPER('&app_schema')
 ORDER BY name, type, referenced_owner, referenced_name;
SPOOL OFF

SPOOL snapshot_&app_schema..triggers.csv
SELECT owner, trigger_name, table_owner, table_name, status, trigger_type, triggering_event
  FROM all_triggers
 WHERE owner = UPPER('&app_schema')
 ORDER BY table_name, trigger_name;
SPOOL OFF

SPOOL snapshot_&app_schema..mviews.csv
SELECT owner, mview_name, container_name, staleness, compile_state, last_refresh_date
  FROM all_mviews
 WHERE owner = UPPER('&app_schema')
 ORDER BY mview_name;
SPOOL OFF

SPOOL snapshot_&app_schema..scheduler_jobs.csv
SELECT owner, job_name, job_type, enabled, state, repeat_interval, last_start_date, next_run_date
  FROM all_scheduler_jobs
 WHERE owner = UPPER('&app_schema')
 ORDER BY job_name;
SPOOL OFF

SPOOL snapshot_&app_schema..db_links.csv
SELECT owner, db_link, username, host, created
  FROM all_db_links
 WHERE owner = UPPER('&app_schema')
 ORDER BY db_link;
SPOOL OFF

SPOOL snapshot_&app_schema..errors.csv
SELECT owner, name, type, line, position, text
  FROM all_errors
 WHERE owner = UPPER('&app_schema')
 ORDER BY name, type, sequence;
SPOOL OFF

SPOOL snapshot_&app_schema..apex_apps.csv
SELECT application_id, application_name, alias, owner, version, status, last_updated_on
  FROM apex_applications
  ORDER BY application_id;
SPOOL OFF

EXIT
