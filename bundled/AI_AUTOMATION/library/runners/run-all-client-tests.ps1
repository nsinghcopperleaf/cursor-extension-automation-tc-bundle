param(
    [string]$ClientName = "HONI",
    [string[]]$TestTypes = @(),
    [bool]$WriteTeardownFile = $false,
    [switch]$FailFast,
    [switch]$OpenDashboard = $true
)

$ErrorActionPreference = "Stop"

$runAllByTypePath = Join-Path $PSScriptRoot "run-all-tests.ps1"
$automationRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$dashboardBuilderPath = Join-Path $PSScriptRoot "build-test-dashboard.ps1"
$clientRoot = Join-Path $automationRoot $ClientName

if (-not (Test-Path $runAllByTypePath)) { throw "Type runner not found: $runAllByTypePath" }
if (-not (Test-Path $clientRoot)) { throw "Client folder not found: $clientRoot" }

if ($TestTypes.Count -eq 0) {
    $TestTypes = @()
    $candidateDirs = Get-ChildItem -Path $clientRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name
    foreach ($dir in $candidateDirs) {
        $testcaseDir = Join-Path $dir.FullName "Testcase"
        if (Test-Path $testcaseDir) {
            $hasTests = @(Get-ChildItem -Path $testcaseDir -File -Filter "*.md" -ErrorAction SilentlyContinue).Count -gt 0
            if ($hasTests) {
                $TestTypes += $dir.Name
            }
        }
    }
}

if ($TestTypes.Count -eq 0) { throw "No test-type folders with markdown testcases found under: $clientRoot" }

$typeResults = @()
$hasFailure = $false

foreach ($testType in $TestTypes) {
    Write-Host "`n=== Running client '$ClientName' test type '$testType' ==="
    
    & $runAllByTypePath -ClientName $ClientName -TestType $testType -WriteTeardownFile $WriteTeardownFile -FailFast:$FailFast -SkipDashboard
    $status = if ($LASTEXITCODE -eq 0) { "Pass" } else { "Fail" }

    $typeResults += [PSCustomObject]@{
        ClientName = $ClientName
        TestType = $testType
        Status = $status
    }

    if ($status -eq "Fail") {
        $hasFailure = $true
        if ($FailFast) { break }
    }
}

$typeResults | Format-Table -AutoSize | Out-String | Write-Host
$overallStatus = if ($hasFailure) { "Fail" } else { "Pass" }
Write-Host "Client run overall status for '$ClientName': $overallStatus"

if (Test-Path $dashboardBuilderPath) {
    try {
        $dashboardPath = & $dashboardBuilderPath -ResultsRoot (Join-Path $automationRoot "test-results")
        if (-not [string]::IsNullOrWhiteSpace($dashboardPath)) {
            Write-Host "Dashboard updated: $dashboardPath"
            if ($OpenDashboard) {
                Start-Process $dashboardPath
            }
        }
    } catch {
        Write-Host "Dashboard update failed: $($_.Exception.Message)"
    }
}

if ($hasFailure) { exit 1 }
exit 0
