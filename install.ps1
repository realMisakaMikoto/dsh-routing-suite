# dsh-routing-suite installer for Windows PowerShell
# Steps: 1) install injector  2) install router presets  3) show restart instructions
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host '=== [1/3] Install injector ===' -ForegroundColor Cyan
$injector = Join-Path $root 'injector'
if (-not (Test-Path (Join-Path $injector 'lib\index.js'))) {
  # A fresh clone has no lib/ because build output is not committed. Installing
  # from GitHub runs the prepare hook. Use the release tgz if a local build fails.
  Write-Host 'injector/lib is missing; running npm install to trigger the prepare build...' -ForegroundColor Yellow
  Push-Location $injector
  try {
    & npm install --no-audit --no-fund 2>&1 | Out-Host
  } catch {
    Write-Host 'npm install failed; continuing with installer guidance' -ForegroundColor DarkGray
  } finally {
    Pop-Location
  }
  if (-not (Test-Path (Join-Path $injector 'lib\index.js'))) {
    Write-Host 'The automatic build did not produce injector/lib. Use one of these methods:' -ForegroundColor Yellow
    Write-Host '  A. Prebuilt release tgz (recommended): https://github.com/yjh051108/dsh-super-injector/releases' -ForegroundColor Yellow
    Write-Host '  B. GitHub install (runs the prepare hook): dsh plugin --profile web add github:yjh051108/dsh-super-injector' -ForegroundColor Yellow
  } else {
    Write-Host 'injector/lib build completed' -ForegroundColor Green
  }
}
if (Test-Path (Join-Path $injector 'lib\index.js')) {
  # Prefer dsh from PATH and fall back to npx for npx-based installations.
  $dshCmd = Get-Command dsh -ErrorAction SilentlyContinue
  if ($dshCmd) {
    & dsh plugin --profile web add $injector 2>&1 | Out-Host
  } else {
    & npx '@deepseek-ai/dsh' plugin --profile web add $injector 2>&1 | Out-Host
  }
  Write-Host 'Injector installed; bundles will take over after restart' -ForegroundColor Green
}

Write-Host '=== [2/3] Install router presets ===' -ForegroundColor Cyan
$presetRoot = Join-Path $root 'preset'
$presets = @('router-standard', 'router-spec')
foreach ($name in $presets) {
  $target = Join-Path $env:USERPROFILE (Join-Path '.dsh\.agent-presets' $name)
  if (Test-Path $target) {
    Write-Host "Preset already exists: $target (remove it manually to replace it)" -ForegroundColor Yellow
    continue
  }
  New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
  # Copy flat: each preset directory must contain agent.cordis.yml directly.
  Copy-Item -Recurse (Join-Path $presetRoot $name) $target
  Write-Host "Preset installed: $target" -ForegroundColor Green
}

# Verify that each preset contains agent.cordis.yml at its top level.
Write-Host '=== Verify preset layout ===' -ForegroundColor Cyan
foreach ($name in $presets) {
  $check = Join-Path $env:USERPROFILE (Join-Path '.dsh\.agent-presets' (Join-Path $name 'agent.cordis.yml'))
  if (Test-Path $check) {
    Write-Host "OK: $name -> agent.cordis.yml found" -ForegroundColor Green
  } else {
    Write-Host "FAIL: $name is missing agent.cordis.yml ($check); DSH will not discover this preset" -ForegroundColor Red
  }
}

Write-Host '=== [3/3] Complete ===' -ForegroundColor Cyan
Write-Host '1. Restart the DSH web service' -ForegroundColor Yellow
Write-Host '2. Start a GUI session and select Router Standard or Router Spec (experimental)' -ForegroundColor Yellow
Write-Host '3. Generation tasks route to react, maintenance tasks to spec, and ambiguous tasks to weak' -ForegroundColor Yellow
Write-Host '4. AI optimization tools: dev_router_status / dev_router_mode / dev_mode_subagent' -ForegroundColor Yellow
