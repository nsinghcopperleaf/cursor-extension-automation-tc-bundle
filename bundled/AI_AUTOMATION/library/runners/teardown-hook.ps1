param(
    [ValidateSet("In Progress", "Pass", "Fail", "Blocked", "Ignored")]
    [string]$Status = "In Progress",
    [string]$ActualResult = "",
    [string]$FailedStep = "",
    [string]$Evidence = "",
    [string]$RunSummary = "",
    [string]$WhatWentWrong = "",
    [string]$WhatWorked = "",
    [string]$Impact = "",
    [string]$RecommendedNextActions = "",
    [string]$TestCaseId = "TC001",
    [string]$ClientName = "HONI",
    [string]$TestType = "Workflow",
    [string]$ExecutionNotesRoot = "",
    [string]$TeardownFileName = "execution-result.md",
    [bool]$WriteTeardownFile = $false,
    [switch]$ResetOnly
)

$ErrorActionPreference = "Stop"
$automationRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$testcaseRoot = Join-Path (Join-Path $automationRoot $ClientName) (Join-Path $TestType "Testcase")

function Get-SafeFolderName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "UNKNOWN_TEST" }
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $safeName = $Name
    foreach ($char in $invalidChars) { $safeName = $safeName.Replace($char, "-") }
    return $safeName.Trim()
}

if ([string]::IsNullOrWhiteSpace($ExecutionNotesRoot)) {
    $safeClientName = Get-SafeFolderName -Name $ClientName
    $safeTestType = Get-SafeFolderName -Name $TestType
    $notesNamespace = "$safeClientName-$safeTestType"
    $ExecutionNotesRoot = Join-Path (Join-Path $automationRoot "test-results") $notesNamespace
}

if ($ResetOnly) {
    $Status = "In Progress"
    $ActualResult = ""
    $FailedStep = ""
    $Evidence = ""
    $RunSummary = ""
    $WhatWentWrong = ""
    $WhatWorked = ""
    $Impact = ""
    $RecommendedNextActions = ""
}

$safeTestCaseId = Get-SafeFolderName -Name $TestCaseId
$caseDir = Join-Path $ExecutionNotesRoot $safeTestCaseId
$screenshotDir = if ($WriteTeardownFile) { Join-Path $caseDir "screenshots" } else { Join-Path $ExecutionNotesRoot "screenshots" }
$teardownPath = Join-Path $caseDir $TeardownFileName
$isFailureStatus = $Status -eq "Fail" -or $Status -eq "Blocked"

if ($WriteTeardownFile) {
    if (-not (Test-Path $caseDir)) { New-Item -ItemType Directory -Path $caseDir -Force | Out-Null }
} elseif (-not (Test-Path $ExecutionNotesRoot)) {
    New-Item -ItemType Directory -Path $ExecutionNotesRoot -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if ($isFailureStatus) {
    if (-not (Test-Path $screenshotDir)) { New-Item -ItemType Directory -Path $screenshotDir -Force | Out-Null }
    $targetEvidence = Join-Path $screenshotDir "$safeTestCaseId-failure.png"
    
    if ([string]::IsNullOrWhiteSpace($Evidence)) {
        $Evidence = $targetEvidence
    } elseif (Test-Path $Evidence) {
        Copy-Item -Path $Evidence -Destination $targetEvidence -Force
        $Evidence = $targetEvidence
    } else {
        $Evidence = $targetEvidence
    }
    
    if (-not (Test-Path $Evidence)) {
        $evidenceDir = Split-Path -Parent $Evidence
        if (-not [string]::IsNullOrWhiteSpace($evidenceDir) -and -not (Test-Path $evidenceDir)) {
            New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
        }
        $placeholderPng = [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7Yb7sAAAAASUVORK5CYII=")
        [System.IO.File]::WriteAllBytes($Evidence, $placeholderPng)
    }
} elseif ([string]::IsNullOrWhiteSpace($Evidence)) {
    $Evidence = "N/A"
}

$screenshotFolderDisplay = if ($isFailureStatus) { $screenshotDir } else { "N/A" }

$content = @"
# Execution Result: $safeTestCaseId

- **Client:** $ClientName
- **Test Type:** $TestType
- **Timestamp:** $timestamp
- **Status:** $Status

## Run Overview
- **Notes Folder:** $caseDir
- **Screenshot Folder:** $screenshotFolderDisplay
- **Failed Step:** $FailedStep
- **Evidence:** $Evidence

## Execution Summary
$ActualResult
"@

if ($WriteTeardownFile) {
    Set-Content -Path $teardownPath -Value $content -Encoding UTF8
    Write-Host "Execution result updated: $teardownPath"
} else {
    Write-Host "Execution result skipped file creation for $safeTestCaseId (WriteTeardownFile=false)."
}

if (-not $ResetOnly -and $WriteTeardownFile) {
    # UPDATE THE SINGLE RUN SUMMARY FILE
    $summaryPath = Join-Path $ExecutionNotesRoot "run-summary.md"
    $tests = @{}

    if (Test-Path $summaryPath) {
        $lines = Get-Content $summaryPath
        foreach ($line in $lines) {
            if ($line -match "^- ([^:]+):\s*(Pass|Fail|Blocked|Ignored)\s*\((.*)\)$") {
                $tests[$matches[1]] = @{ Status = $matches[2]; File = $matches[3] }
            }
        }
    }

    $currentFileName = "$safeTestCaseId.md"
    if (Test-Path $testcaseRoot) {
        $candidates = Get-ChildItem -Path $testcaseRoot -File -Filter "$TestCaseId*.md" -ErrorAction SilentlyContinue | Sort-Object Name
        if ($candidates.Count -gt 0) { $currentFileName = $candidates[0].Name }
    }

    $tests[$safeTestCaseId] = @{ Status = $Status; File = $currentFileName }

    $total = $tests.Count
    $passed = 0; $failed = 0; $ignored = 0
    foreach ($k in $tests.Keys) {
        if ($tests[$k].Status -eq "Pass") { $passed++ }
        elseif ($tests[$k].Status -eq "Fail" -or $tests[$k].Status -eq "Blocked") { $failed++ }
        elseif ($tests[$k].Status -eq "Ignored") { $ignored++ }
    }
    $overall = if ($failed -gt 0) { "Fail" } else { "Pass" }

    $summaryLines = @(
        "# Run Summary",
        "",
        "- Client: $ClientName",
        "- Test Type: $TestType",
        "- Test Folder: $testcaseRoot",
        "- Timestamp: $timestamp",
        "- Overall Status: $overall",
        "- Total: $total",
        "- Passed: $passed",
        "- Failed: $failed",
        "- Ignored: $ignored",
        "",
        "## Test Results",
        ""
    )
    
    foreach ($k in ($tests.Keys | Sort-Object)) {
        $summaryLines += "- ${k}: $($tests[$k].Status) ($($tests[$k].File))"
    }

    Set-Content -Path $summaryPath -Value ($summaryLines -join [Environment]::NewLine) -Encoding UTF8
    Write-Host "Global run summary updated: $summaryPath"
}
