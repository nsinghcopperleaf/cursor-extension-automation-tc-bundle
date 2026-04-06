param(
    [string]$ClientName = "HONI",
    [string]$TestType = "Workflow",
    [string]$TestFolder = "",
    [bool]$WriteTeardownFile = $false,
    [switch]$FailFast,
    [switch]$SkipDashboard,
    [switch]$OpenDashboard = $true
)

$ErrorActionPreference = "Stop"

function Get-SafeFolderName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "UNKNOWN" }
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $safeName = $Name
    foreach ($char in $invalidChars) { $safeName = $safeName.Replace($char, "-") }
    return $safeName.Trim()
}

$runnerPath = Join-Path $PSScriptRoot "run-test-with-hooks.ps1"
if (-not (Test-Path $runnerPath)) { throw "Single-test runner not found: $runnerPath" }
$automationRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$dashboardBuilderPath = Join-Path $PSScriptRoot "build-test-dashboard.ps1"

if ([string]::IsNullOrWhiteSpace($TestFolder)) {
    $TestFolder = Join-Path (Join-Path $automationRoot $ClientName) (Join-Path $TestType "Testcase")
}

if (-not (Test-Path $TestFolder)) { throw "Test folder not found: $TestFolder" }

$testFiles = Get-ChildItem -Path $TestFolder -File -Filter "*.md" | Sort-Object Name
if ($testFiles.Count -eq 0) {
    Write-Host "No markdown testcases found in: $TestFolder"
    exit 1
}

$results = @()
$hasFailure = $false

foreach ($testFile in $testFiles) {
    $match = [regex]::Match($testFile.BaseName, "TC\d+")
    $testCaseId = if ($match.Success) { $match.Value } else { $testFile.BaseName }

    Write-Host "Running $($testFile.Name) as $testCaseId ..."
    & $runnerPath `
        -ClientName $ClientName `
        -TestType $TestType `
        -TestCaseId $testCaseId `
        -TestCaseFile $testFile.FullName `
        -WriteTeardownFile $WriteTeardownFile `
        -LoginStatus "Pass" `
        -TestStatus "Pass" `
        -SkipDashboard

    $status = if ($LASTEXITCODE -eq 0) { "Pass" } elseif ($LASTEXITCODE -eq 2) { "Ignored" } else { "Fail" }
    $results += [PSCustomObject]@{
        TestCaseId = $testCaseId
        Status = $status
        File = $testFile.Name
    }

    if ($status -eq "Fail") {
        $hasFailure = $true
        if ($FailFast) { break }
    }
}

$results | Format-Table -AutoSize | Out-String | Write-Host

if (-not $SkipDashboard -and (Test-Path $dashboardBuilderPath)) {
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
