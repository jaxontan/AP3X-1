<#
.SYNOPSIS
  Unified End-to-End Deployment Script for Oracle APEX & SmartDB (Step 1 + Step 2).

.DESCRIPTION
  Executes full deployment:
    1. Schema & Package Deployment (Step 1): Deploys schema.sql, packages/*.pks, packages/*.pkb.
    2. Unit Testing: Runs database tests/*.sql and asserts 0 failures.
    3. Workspace & User Provisioning: Ensures workspace and test personas exist.
    4. APEX Application Import (Step 2): Normalizes and imports working/app into the workspace.
#>
[CmdletBinding()]
param(
    [string]$AppDirectory = 'working/app',
    [string]$DatabaseDirectory = 'working/database',
    # Defaults to workspace.name in <AppDirectory>/deployments/default.json.
    [string]$Workspace,
    # Extra APEX end users to provision (all get the local password), e.g. -TestUsers EMP1,MGR1.
    [string[]]$TestUsers = @(),
    [string]$ConnectionString = $env:SQLCL_CONNECTION_STRING,
    [switch]$Local = $true,
    [switch]$SkipTests = $false
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'set-env.ps1')

if (-not $env:SQLCL_BIN -or -not (Test-Path $env:SQLCL_BIN)) {
    Write-Error 'SQLCL_BIN executable not found.'
    exit 2
}

if (-not $Workspace) {
    $deploymentFile = Join-Path $AppDirectory 'deployments\default.json'
    if (Test-Path -LiteralPath $deploymentFile) {
        $Workspace = [string](Get-Content -LiteralPath $deploymentFile -Raw | ConvertFrom-Json).workspace.name
    }
}
if (-not $Workspace) {
    Write-Error "No workspace: pass -Workspace or set workspace.name in $AppDirectory/deployments/default.json."
    exit 2
}
$Workspace = $Workspace.ToUpperInvariant()
if ($Workspace -notmatch '^[A-Z][A-Z0-9_]{0,29}$') {
    Write-Error "Workspace '$Workspace' must be a valid Oracle identifier."
    exit 2
}
$TestUsers = @($TestUsers | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToUpperInvariant() } | Where-Object { $_ })
foreach ($user in $TestUsers) {
    if ($user -notmatch '^[A-Z][A-Z0-9_]{0,29}$') {
        Write-Error "Test user '$user' must be a valid identifier."
        exit 2
    }
}
$testUserCalls = ($TestUsers | ForEach-Object { "    create_ws_user('$_', '$($_.ToLowerInvariant())@example.com', 'USER');" }) -join "`n"

$localPwd = if ($env:ORACLE_PASSWORD) { $env:ORACLE_PASSWORD } else { 'Oracle123!' }
$localService = if ($env:LOCAL_SERVICE) { $env:LOCAL_SERVICE } else { 'myatp' }
$adminConn = "ADMIN/`"$localPwd`"@localhost:1521/$localService"
$schemaConn = "$Workspace/`"$localPwd`"@localhost:1521/$localService"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Starting Unified Deployment: Step 1 (DB) & Step 2 (APEX)" -ForegroundColor Cyan
Write-Host " Target Workspace & Schema: $Workspace" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. Provision User, Schema, Workspace, and Test Accounts
# -----------------------------------------------------------------------------
Write-Host "[1/4] Provisioning Workspace, Schema, and Test Accounts..." -ForegroundColor Yellow

$provisionScript = @"
connect $adminConn
whenever sqlerror exit failure rollback;

declare
  l_count number;
begin
  select count(*) into l_count from all_users where username = upper('$Workspace');
  if l_count = 0 then
    execute immediate 'create user $Workspace identified by "$localPwd" default tablespace DATA quota unlimited on DATA';
    dbms_output.put_line('Created user $Workspace.');
  end if;
  execute immediate 'alter user $Workspace quota unlimited on DATA';
  execute immediate 'grant connect, resource, create session, create table, create view, create procedure, create sequence, create trigger, create job to $Workspace';
end;
/

declare
  l_ws varchar2(255) := upper('$Workspace');
  l_ws_id number;
  l_count number;

  procedure create_ws_user(p_user varchar2, p_email varchar2, p_role varchar2) is
    l_u_cnt number;
  begin
    select count(*) into l_u_cnt
      from apex_workspace_apex_users
     where workspace_name = l_ws
       and user_name = upper(p_user);

    if l_u_cnt = 0 then
      apex_util.create_user(
        p_user_name                    => upper(p_user),
        p_web_password                 => '$localPwd',
        p_email_address                => p_email,
        p_default_schema               => l_ws,
        p_developer_privs              => case when p_role = 'ADMIN' then 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL' else null end,
        p_change_password_on_first_use => 'N'
      );
      dbms_output.put_line('Created workspace user ' || p_user);
    end if;
  end;

begin
  select count(*) into l_count from apex_workspaces where workspace = l_ws;
  if l_count = 0 then
    apex_instance_admin.add_workspace(
      p_workspace_id       => null,
      p_workspace          => l_ws,
      p_primary_schema     => l_ws,
      p_additional_schemas => null
    );
    dbms_output.put_line('Created workspace ' || l_ws);
  end if;

  l_ws_id := apex_util.find_security_group_id(p_workspace => l_ws);
  if l_ws_id is not null then
    apex_util.set_security_group_id(l_ws_id);
    create_ws_user('ADMIN', 'admin@example.com', 'ADMIN');
$testUserCalls
    commit;
  end if;
end;
/
exit
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($tmpFile, $provisionScript, (New-Object System.Text.UTF8Encoding($false)))
    & $env:SQLCL_BIN /nolog "@$tmpFile" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Workspace provisioning failed with exit code $LASTEXITCODE"
        exit 1
    }
}
finally {
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
}

# -----------------------------------------------------------------------------
# 2. Deploy Database Schema, Packages, and Run Tests (Step 1)
# -----------------------------------------------------------------------------
Write-Host "[2/4] Deploying Database Schema & SmartDB Packages..." -ForegroundColor Yellow

$schemaFile = Join-Path $DatabaseDirectory 'schema.sql'
$pksFiles = Get-ChildItem (Join-Path $DatabaseDirectory 'packages') -Filter '*.pks' -ErrorAction SilentlyContinue
$pkbFiles = Get-ChildItem (Join-Path $DatabaseDirectory 'packages') -Filter '*.pkb' -ErrorAction SilentlyContinue
$testFiles = Get-ChildItem (Join-Path $DatabaseDirectory 'tests') -Filter '*.sql' -ErrorAction SilentlyContinue

$dbScriptLines = @(
    "connect $schemaConn",
    "whenever sqlerror exit failure rollback;"
)

if (Test-Path $schemaFile) {
    $dbScriptLines += "prompt Deploying schema.sql..."
    $dbScriptLines += "@$schemaFile"
}

foreach ($pks in $pksFiles) {
    $dbScriptLines += "prompt Deploying $($pks.Name)..."
    $dbScriptLines += "@$($pks.FullName)"
}

foreach ($pkb in $pkbFiles) {
    $dbScriptLines += "prompt Deploying $($pkb.Name)..."
    $dbScriptLines += "@$($pkb.FullName)"
}

if (-not $SkipTests) {
    foreach ($test in $testFiles) {
        $dbScriptLines += "prompt Running test $($test.Name)..."
        $dbScriptLines += "@$($test.FullName)"
    }
}

$dbScriptLines += "exit"
$dbScript = $dbScriptLines -join "`n"

$tmpFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($tmpFile, $dbScript, (New-Object System.Text.UTF8Encoding($false)))
    $dbOutput = & $env:SQLCL_BIN /nolog "@$tmpFile" 2>&1
    $dbExit = $LASTEXITCODE
    $dbText = $dbOutput | Out-String
    if ($dbExit -ne 0 -or $dbText -match 'ORA-\d{3,5}' -or $dbText -match '\[FAIL\]') {
        Write-Host $dbText
        Write-Error "Database deployment or tests failed."
        exit 1
    }
    Write-Host "Database schema, packages, and unit tests passed successfully." -ForegroundColor Green
}
finally {
    Remove-Item $tmpFile -ErrorAction SilentlyContinue
}

# -----------------------------------------------------------------------------
# 3. Validate & Normalize APEX Application Tree
# -----------------------------------------------------------------------------
Write-Host "[3/4] Normalizing and Validating APEX Application Tree..." -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'normalize-apx-tree.ps1') -AppDirectory $AppDirectory | Out-Null
$valOutput = & (Join-Path $PSScriptRoot 'validate-apex-app.ps1') -AppDirectory $AppDirectory 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ($valOutput | Out-String)
    Write-Error "APEX validation failed."
    exit 1
}

# -----------------------------------------------------------------------------
# 4. Import APEX Application (Step 2)
# -----------------------------------------------------------------------------
Write-Host "[4/4] Importing APEX Application into Workspace $Workspace..." -ForegroundColor Yellow
$deployOutput = & (Join-Path $PSScriptRoot 'deploy-apex-app.ps1') -AppDirectory $AppDirectory -Workspace $Workspace -Local -Force 2>&1
$deployExit = $LASTEXITCODE
$deployText = $deployOutput | Out-String
Write-Host $deployText.TrimEnd()

if ($deployExit -ne 0) {
    Write-Error "APEX Application Import failed."
    exit 1
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Unified Deployment Completed Successfully!" -ForegroundColor Green
Write-Host " APEX URL:   https://localhost:8443/ords/apex" -ForegroundColor Green
Write-Host " Workspace:  $Workspace" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
exit 0
