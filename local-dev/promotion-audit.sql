-- Read-only pre-promotion audit.
-- Usage:
--   sql /nolog -name apex_commercial_ro @local-dev/promotion-audit.sql APP
-- The first positional argument is the application schema. The output is a
-- text report in promotion_audit_<schema>.txt. This script never changes data.
-- Run it against the commercial target before promoting local artifacts.

SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET HEADING ON
SET PAGESIZE 200
SET LINESIZE 240
SET LONG 100000
SET TRIMSPOOL ON
SET SQLFORMAT ANSICONSOLE
SET TERMOUT OFF
SET DEFINE ON

DEFINE app_schema = &1

SPOOL promotion_audit_&app_schema..txt

PROMPT ============================================================
PROMPT Oracle APEX promotion audit
PROMPT Schema: &app_schema
PROMPT This report is read-only. It does not replace a target test.
PROMPT ============================================================
PROMPT
PROMPT [1] Database components and versions
SELECT product, version, status
  FROM product_component_version
 ORDER BY product;

PROMPT
PROMPT [2] APEX release (if APEX is installed)
SELECT version_no
  FROM apex_release;

PROMPT
PROMPT [3] APEX applications (if APEX is installed)
SELECT application_id, application_name, alias, owner, version, status, last_updated_on
  FROM apex_applications
 ORDER BY application_id;

PROMPT
PROMPT [4] Invalid objects
SELECT owner, object_name, object_type, status, last_ddl_time
  FROM all_objects
 WHERE owner = UPPER('&app_schema')
   AND status <> 'VALID'
 ORDER BY object_type, object_name;

PROMPT
PROMPT [5] Compilation errors
SELECT owner, name, type, line, position, text
  FROM all_errors
 WHERE owner = UPPER('&app_schema')
 ORDER BY name, type, sequence;

PROMPT
PROMPT [6] Disabled or non-validated constraints
SELECT owner, table_name, constraint_name, constraint_type, status, validated
  FROM all_constraints
 WHERE owner = UPPER('&app_schema')
   AND (status <> 'ENABLED' OR validated <> 'VALIDATED')
 ORDER BY table_name, constraint_name;

PROMPT
PROMPT [7] Unusable or invisible indexes
SELECT owner, index_name, table_name, status, visibility
  FROM all_indexes
 WHERE table_owner = UPPER('&app_schema')
   AND (status <> 'VALID' OR visibility <> 'VISIBLE')
 ORDER BY table_name, index_name;

PROMPT
PROMPT [8] Disabled triggers
SELECT owner, trigger_name, table_owner, table_name, status, trigger_type
  FROM all_triggers
 WHERE owner = UPPER('&app_schema')
   AND status <> 'ENABLED'
 ORDER BY table_name, trigger_name;

PROMPT
PROMPT [9] Tables without a primary key
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

PROMPT
PROMPT [10] Foreign keys without a matching index (heuristic)
SELECT c.owner, c.table_name, c.constraint_name, cc.column_name
  FROM all_constraints c
  JOIN all_cons_columns cc
    ON cc.owner = c.owner
   AND cc.constraint_name = c.constraint_name
 WHERE c.owner = UPPER('&app_schema')
   AND c.constraint_type = 'R'
   AND NOT EXISTS (
       SELECT 1
         FROM all_ind_columns ic
         JOIN all_indexes i
           ON i.owner = ic.index_owner
          AND i.index_name = ic.index_name
        WHERE i.table_owner = c.owner
          AND i.table_name = c.table_name
          AND ic.column_name = cc.column_name
          AND ic.column_position = cc.position
   )
 ORDER BY c.table_name, c.constraint_name, cc.position;

PROMPT
PROMPT [11] Direct grants to PUBLIC
SELECT grantee, owner, table_name, privilege, grantable
  FROM all_tab_privs
 WHERE owner = UPPER('&app_schema')
   AND grantee = 'PUBLIC'
 ORDER BY table_name, privilege;

PROMPT
PROMPT [12] Public synonyms that point at the application schema
SELECT owner, synonym_name, table_owner, table_name, db_link
  FROM all_synonyms
 WHERE owner = 'PUBLIC'
   AND table_owner = UPPER('&app_schema')
 ORDER BY synonym_name;

PROMPT
PROMPT [13] Database links owned by the schema
SELECT owner, db_link, username, host, created
  FROM all_db_links
 WHERE owner = UPPER('&app_schema')
 ORDER BY db_link;

PROMPT
PROMPT [14] Directory objects visible to this session
SELECT owner, directory_name, directory_path
  FROM all_directories
 ORDER BY directory_name;

PROMPT
PROMPT [15] Enabled scheduler jobs
SELECT owner, job_name, job_type, enabled, state, repeat_interval, next_run_date
  FROM all_scheduler_jobs
 WHERE owner = UPPER('&app_schema')
   AND enabled = 'TRUE'
 ORDER BY job_name;

PROMPT
PROMPT [16] Java classes
SELECT owner, COUNT(*) AS java_class_count
  FROM all_java_classes
 WHERE owner = UPPER('&app_schema')
 GROUP BY owner;

PROMPT
PROMPT [17] Stale materialized views
SELECT owner, mview_name, staleness, compile_state, last_refresh_date
  FROM all_mviews
 WHERE owner = UPPER('&app_schema')
   AND staleness <> 'FRESH'
 ORDER BY mview_name;

PROMPT
PROMPT [18] High-risk session privileges
SELECT privilege
  FROM session_privs
 WHERE privilege IN (
       'SELECT ANY TABLE',
       'INSERT ANY TABLE',
       'UPDATE ANY TABLE',
       'DELETE ANY TABLE',
       'DROP ANY TABLE',
       'CREATE ANY TABLE',
       'ALTER ANY TABLE',
       'GRANT ANY PRIVILEGE',
       'ALTER SYSTEM',
       'CREATE ANY PROCEDURE',
       'EXECUTE ANY PROCEDURE',
       'CREATE ANY JOB',
       'CREATE ANY DIRECTORY'
 )
 ORDER BY privilege;

PROMPT
PROMPT [19] Current-user roles
SELECT username, granted_role, admin_option, default_role
  FROM user_role_privs
 ORDER BY granted_role;

PROMPT
PROMPT [20] 23ai/26ai-only column types (review when the target is 19c)
SELECT owner, table_name, column_name, data_type
  FROM all_tab_columns
 WHERE owner = UPPER('&app_schema')
   AND data_type IN ('BOOLEAN', 'JSON', 'VECTOR')
 ORDER BY table_name, column_id;

PROMPT
PROMPT [21] Dependencies on SYS/SYSTEM beyond a small baseline
SELECT owner, name, type, referenced_owner, referenced_name, referenced_type
  FROM all_dependencies
 WHERE owner = UPPER('&app_schema')
   AND referenced_owner IN ('SYS', 'SYSTEM')
   AND referenced_name NOT IN (
       'STANDARD',
       'DBMS_STANDARD',
       'DBMS_OUTPUT',
       'DBMS_UTILITY',
       'DBMS_ASSERT',
       'DBMS_LOB',
       'DBMS_CRYPTO',
       'DBMS_SQL',
       'DBMS_SCHEDULER',
       'DBMS_MVIEW',
       'DBMS_METADATA',
       'DBMS_RANDOM',
       'DBMS_APPLICATION_INFO',
       'DBMS_SESSION',
       'DBMS_LOCK',
       'DBMS_PROFILER',
       'DBMS_HPROF',
       'DBMS_XPLAN',
       'DBMS_ERRLOG',
       'UTL_RAW',
       'PLITBLM'
   )
 ORDER BY name, referenced_name;

PROMPT
PROMPT [22] NLS database settings
SELECT parameter, value
  FROM nls_database_parameters
 WHERE parameter IN (
       'NLS_CHARACTERSET',
       'NLS_NCHAR_CHARACTERSET',
       'NLS_LANGUAGE',
       'NLS_TERRITORY'
 )
 ORDER BY parameter;

PROMPT
PROMPT [23] Object counts
SELECT object_type, COUNT(*) AS object_count
  FROM all_objects
 WHERE owner = UPPER('&app_schema')
 GROUP BY object_type
 ORDER BY object_type;

PROMPT
PROMPT ============================================================
PROMPT End of audit. Review every section before promotion.
PROMPT A clean report is necessary, not sufficient: test on the target.
PROMPT ============================================================

SPOOL OFF
EXIT
