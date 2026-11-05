import { spawn } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const sqlclBin = process.env.SQLCL_BIN || path.resolve('tools/sqlcl/bin/sql.exe');
const connStr = process.env.SQLCL_CONNECTION_STRING || 'SGINT02/"Oracle26ai!2026"@192.168.1.103:1521/FREEPDB1';

console.log('Connecting to remote database at 192.168.1.103:1521/FREEPDB1 as SGINT02...');

const sqlFiles = [
    'working/database/schema.sql',
    'working/database/fc_apex_error_handler.sql',
    'working/database/packages/fc_audit_api.pks',
    'working/database/packages/fc_security_api.pks',
    'working/database/packages/fc_workflow_api.pks',
    'working/database/packages/fc_ai_agent_api.pks',
    'working/database/packages/fc_planning_api.pks',
    'working/database/packages/fc_deck_api.pks',
    'working/database/packages/fc_design_api.pks',
    'working/database/packages/fc_costing_api.pks',
    'working/database/packages/fc_audit_api.pkb',
    'working/database/packages/fc_security_api.pkb',
    'working/database/packages/fc_workflow_api.pkb',
    'working/database/packages/fc_ai_agent_api.pkb',
    'working/database/packages/fc_planning_api.pkb',
    'working/database/packages/fc_deck_api.pkb',
    'working/database/packages/fc_design_api.pkb',
    'working/database/packages/fc_costing_api.pkb',
    'working/database/tests/test_flash_concepts.sql'
];

let scriptCommands = `SET SERVEROUTPUT ON SIZE UNLIMITED;\nSET DEFINE OFF;\nSET ECHO ON;\n`;
for (const file of sqlFiles) {
    const full = path.resolve(file).replace(/\\/g, '/');
    scriptCommands += `PROMPT >>> RUNNING: ${file} <<<\n@"${full}"\n`;
}
scriptCommands += `PROMPT >>> CHECKING INVALID FLASH CONCEPTS OBJECTS <<<\nSELECT object_type, object_name, status FROM user_objects WHERE object_name LIKE 'FC_%' AND status != 'VALID';\nEXIT;\n`;

const tempFile = path.resolve('scripts/temp-deploy-db.sql');
fs.writeFileSync(tempFile, scriptCommands, 'utf8');

const child = spawn(sqlclBin, ['-L', connStr, `@${tempFile}`], {
    stdio: ['inherit', 'pipe', 'pipe']
});

let stdout = '';
let stderr = '';

child.stdout.on('data', d => {
    stdout += d.toString();
    process.stdout.write(d);
});

child.stderr.on('data', d => {
    stderr += d.toString();
    process.stderr.write(d);
});

child.on('close', code => {
    fs.unlinkSync(tempFile);
    console.log(`\nSQLcl exited with code ${code}`);
    
    // Check for compilation errors or test failures
    const hasCompilationErrors = /Warning: Package Body created with compilation errors|Compilation errors for/i.test(stdout);
    const hasFailedTests = /Failed: [1-9]\d*/i.test(stdout);
    const hasUnhandledException = /ERROR at line 1:/i.test(stdout);

    if (code !== 0 || hasCompilationErrors || hasFailedTests || hasUnhandledException) {
        console.error('Database deployment encountered errors!');
        process.exit(1);
    } else {
        console.log('\n=============================================================');
        console.log('Database schema, packages, and tests successfully deployed!');
        console.log('All Flash Concepts packages are VALID and tests PASSED.');
        console.log('=============================================================');
        process.exit(0);
    }
});
