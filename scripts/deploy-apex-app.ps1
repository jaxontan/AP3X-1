[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$AppDirectory,

    [string]$ConnectionString = $env:SQLCL_CONNECTION_STRING,

    [switch]$Local,

    [string]$Workspace,

    [int]$ApplicationId,

    [switch]$Force
)

if ($Force) {
    $ConfirmPreference = 'None'
}

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'set-env.ps1')

if (-not $env:SQLCL_BIN) {
    Write-Error 'SQLCL_BIN is not set. Run scripts\install-sqlcl.ps1 or set SQLCL_BIN to the SQLcl executable.' -ErrorAction Continue
    exit 2
}

if (-not (Test-Path $env:SQLCL_BIN)) {
    Write-Error "SQLCL_BIN is not a file: $env:SQLCL_BIN" -ErrorAction Continue
    exit 2
}

if (-not (Test-Path $AppDirectory -PathType Container)) {
    Write-Error "Application directory does not exist: $AppDirectory" -ErrorAction Continue
    exit 2
}

$resolved = (Resolve-Path $AppDirectory).Path
if ($resolved -match '["\r\n]') {
    Write-Error 'Application directory contains unsupported SQLcl command characters (quote or newline).' -ErrorAction Continue
    exit 2
}

$crlfFiles = @()
$bomFiles = @()
foreach ($file in Get-ChildItem $resolved -Recurse -File -Filter '*.apx') {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    if ($bytes -contains 13) {
        $crlfFiles += $file.FullName
    }
    $hasUtf8Bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $hasUtf16Bom = ($bytes.Length -ge 2 -and (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) -or ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF)))
    if ($hasUtf8Bom -or $hasUtf16Bom) {
        $bomFiles += $file.FullName
    }
}

if ($crlfFiles.Count -gt 0) {
    Write-Host 'APEXLang sources must use LF line endings. CRLF was found in:' -ForegroundColor Red
    $crlfFiles | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    if ($crlfFiles.Count -gt 10) {
        Write-Host ("  ... and {0} more" -f ($crlfFiles.Count - 10))
    }
    Write-Host ''
    Write-Host 'Fix and re-run deployment:' -ForegroundColor Yellow
    Write-Host ("  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\normalize-apx-tree.ps1 -AppDirectory `"$resolved`"")
    exit 2
}

if ($bomFiles.Count -gt 0) {
    Write-Host 'APEXLang sources must be UTF-8 without a byte-order mark. A BOM was found in:' -ForegroundColor Red
    $bomFiles | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
    if ($bomFiles.Count -gt 10) {
        Write-Host ("  ... and {0} more" -f ($bomFiles.Count - 10))
    }
    Write-Host ''
    Write-Host 'Fix and re-run deployment:' -ForegroundColor Yellow
    Write-Host ("  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\normalize-apx-tree.ps1 -AppDirectory `"$resolved`"")
    exit 2
}

if ($Local) {
    if (-not $ConnectionString) {
        $localPwd = if ($env:ORACLE_PASSWORD) { $env:ORACLE_PASSWORD } else { 'Welcome123456#' }
        $localService = if ($env:LOCAL_SERVICE) { $env:LOCAL_SERVICE } else { 'myatp' }
        $ConnectionString = "ADMIN/`"$localPwd`"@localhost:1521/$localService"
    }
    if (-not $Workspace) {
        $Workspace = if ($env:APEX_WORKSPACE) { $env:APEX_WORKSPACE } else { 'DEV' }
    }
}

$workspaceClause = if ($Workspace) { "-workspace `"$Workspace`"" } else { "" }

$provisionSql = ""
if ($Workspace) {
    $adminPwd = if ($env:ORACLE_PASSWORD) { $env:ORACLE_PASSWORD } else { 'Welcome123456#' }
    $provisionSql = @"
declare
  l_ws varchar2(255) := upper('$Workspace');
  l_ws_id number;
  l_count number;
begin
  -- Check if workspace exists
  select count(*) into l_count from all_views where view_name = 'APEX_WORKSPACES';
  if l_count > 0 then
    begin
      select workspace_id into l_ws_id from apex_workspaces where workspace = l_ws;
    exception
      when no_data_found then
        begin
          apex_instance_admin.add_workspace(
            p_workspace_id       => null,
            p_workspace          => l_ws,
            p_primary_schema     => l_ws,
            p_additional_schemas => null
          );
          l_ws_id := apex_util.find_security_group_id(p_workspace => l_ws);
        exception
          when others then
            dbms_output.put_line('Workspace provisioning notice: ' || sqlerrm);
        end;
    end;

    if l_ws_id is not null then
      apex_util.set_security_group_id(l_ws_id);

      -- Ensure ADMIN user exists
      select count(*) into l_count
        from apex_workspace_apex_users
       where workspace_name = l_ws
         and user_name = 'ADMIN';

      if l_count = 0 then
        begin
          apex_util.create_user(
            p_user_name                    => 'ADMIN',
            p_web_password                 => '$adminPwd',
            p_email_address                => 'admin@example.com',
            p_default_schema               => l_ws,
            p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
            p_change_password_on_first_use => 'N'
          );
          commit;
          dbms_output.put_line('Auto-provisioned ADMIN user for workspace ' || l_ws);
        exception
          when others then
            dbms_output.put_line('ADMIN user creation notice: ' || sqlerrm);
        end;
      end if;
    end if;
  end if;
exception
  when others then
    dbms_output.put_line('Workspace auto-provision notice: ' || sqlerrm);
end;
/
"@
}

$appIdSql = if ($ApplicationId -gt 0) {
    "apex_application_install.set_application_id($ApplicationId);`n  apex_application_install.generate_offset;"
} else { "" }

$commands = @"
begin
  apex_application_install.set_auto_install_sup_obj(
    p_auto_install_sup_obj => true
  );
  $appIdSql
end;
/
$provisionSql
apex import -input "$resolved" $workspaceClause
exit
"@

Write-Host "Application directory: $resolved"
Write-Host "SQLcl: $env:SQLCL_BIN"
Write-Host ("Target connection: {0}" -f $(if ($ConnectionString) { $(if ($Local) { "local sandbox (ADMIN@localhost:1521/$localService, workspace: $Workspace)" } else { '(set; hidden)' }) } else { '(not set)' }))

if ($WhatIfPreference) {
    Write-Host ''
    Write-Host 'WhatIf: SQLcl would run the following commands:' -ForegroundColor Yellow
    Write-Host $commands
    exit 0
}

if (-not $ConnectionString) {
    Write-Error 'SQLCL_CONNECTION_STRING is not set. Set it, or pass -ConnectionString, before deploying.' -ErrorAction Continue
    exit 2
}

if (-not $PSCmdlet.ShouldProcess($resolved, 'Import the APEX application into the target database')) {
    exit 0
}

$tempDeployFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($tempDeployFile, $commands, (New-Object System.Text.UTF8Encoding($false)))
    $output = Get-Content -LiteralPath $tempDeployFile | & $env:SQLCL_BIN $ConnectionString "@$tempDeployFile" 2>&1
}
finally {
    Remove-Item -LiteralPath $tempDeployFile -ErrorAction SilentlyContinue
}
$status = $LASTEXITCODE
$text = $output | Out-String
$text.TrimEnd() | Write-Host

if ($status -ne 0) {
    Write-Error "APEX import failed with exit code $status."
    exit 1
}

if ($text -match 'ORA-\d{3,5}') {
    Write-Error 'APEX import produced ORA- errors. Treating the deployment as failed even though the process exited 0.'
    exit 1
}

if ($text -match '\bFILE_IGNORED\b' -or $text -match 'APEXlang Compile Errors' -or $text -match '(?m)^\s*Error:') {
    Write-Error 'APEX import reported skipped files or compile diagnostics. Treating the deployment as failed.'
    exit 1
}

Write-Host 'APEX import completed without ORA- errors.' -ForegroundColor Green
exit 0
