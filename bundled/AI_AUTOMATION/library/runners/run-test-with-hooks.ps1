param(
    [string]$TestCaseId = "TC001",
    [string]$ClientName = "HONI",
    [string]$TestType = "Workflow",
    [string]$TestCaseFile = "",
    [bool]$WriteTeardownFile = $false,
    [ValidateSet("Pass", "Fail", "Blocked", "Ignored")]
    [string]$LoginStatus = "Pass",
    [ValidateSet("Pass", "Fail", "Blocked", "Ignored")]
    [string]$TestStatus = "Pass",
    [string]$FailedStep = "",
    [string]$Evidence = "",
    [switch]$SkipDashboard,
    [switch]$OpenDashboard = $true
)

$ErrorActionPreference = "Stop"

$loginHookPath = Join-Path $PSScriptRoot "login-hook.ps1"
$teardownHookPath = Join-Path $PSScriptRoot "teardown-hook.ps1"
$automationRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$dashboardBuilderPath = Join-Path $PSScriptRoot "build-test-dashboard.ps1"
$executionNotesBase = Join-Path $automationRoot "test-results"

function Update-Dashboard {
    if (-not $SkipDashboard -and (Test-Path $dashboardBuilderPath)) {
        try {
            $dashboardPath = & $dashboardBuilderPath -ResultsRoot $executionNotesBase
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
}

function Get-SafeFolderName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "UNKNOWN_TEST" }
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $safeName = $Name
    foreach ($char in $invalidChars) { $safeName = $safeName.Replace($char, "-") }
    return $safeName.Trim()
}

$safeClientName = Get-SafeFolderName -Name $ClientName
$safeTestType = Get-SafeFolderName -Name $TestType
$notesNamespace = "$safeClientName-$safeTestType"
$executionNotesRoot = Join-Path $executionNotesBase $notesNamespace
$safeTestCaseId = Get-SafeFolderName -Name $TestCaseId
$caseNotesPath = Join-Path $executionNotesRoot $safeTestCaseId
$testcaseRoot = Join-Path (Join-Path $automationRoot $ClientName) (Join-Path $TestType "Testcase")
$cleanupTarget = Join-Path $executionNotesRoot $safeTestCaseId

if (-not (Test-Path $loginHookPath)) { throw "Missing login hook: $loginHookPath" }
if (-not (Test-Path $teardownHookPath)) { throw "Missing teardown hook: $teardownHookPath" }

if ([string]::IsNullOrWhiteSpace($TestCaseFile)) {
    if (Test-Path $testcaseRoot) {
        $candidates = Get-ChildItem -Path $testcaseRoot -File -Filter "$TestCaseId*.md" -ErrorAction SilentlyContinue | Sort-Object Name
        if ($candidates.Count -gt 0) { $TestCaseFile = $candidates[0].FullName }
    }
}

if (-not [string]::IsNullOrWhiteSpace($TestCaseFile) -and (Test-Path $TestCaseFile)) {
    $content = Get-Content -Path $TestCaseFile -TotalCount 20 -ErrorAction SilentlyContinue
    $isIgnored = $false
    foreach ($line in $content) {
        if ($line -match "^\-\s*(Status:\s*Ignored|Ignore:\s*true)\s*$") {
            $isIgnored = $true
            break
        }
    }

    if ($isIgnored) {
        Write-Host "[$TestCaseId] Test case is marked as ignored. Skipping execution."
        if (-not (Test-Path $executionNotesRoot)) { New-Item -ItemType Directory -Path $executionNotesRoot -Force | Out-Null }
        if (Test-Path $caseNotesPath) { Remove-Item -Path $caseNotesPath -Recurse -Force }
        & $teardownHookPath `
            -Status "Ignored" `
            -ActualResult "Test case execution was skipped due to ignore flag in file." `
            -FailedStep "N/A" `
            -Evidence "N/A" `
            -RunSummary "$TestCaseId ignored." `
            -WhatWentWrong "N/A" `
            -WhatWorked "N/A" `
            -Impact "N/A" `
            -RecommendedNextActions "Remove ignore flag to execute." `
            -ClientName $ClientName `
            -TestType $TestType `
            -TestCaseId $TestCaseId `
            -WriteTeardownFile $true `
            -ExecutionNotesRoot $executionNotesRoot
        Update-Dashboard
        exit 2
    }
}

Write-Host "[$TestCaseId] Rerun cleanup: resetting notes at $cleanupTarget."
if (-not (Test-Path $executionNotesRoot)) { New-Item -ItemType Directory -Path $executionNotesRoot -Force | Out-Null }
if (Test-Path $caseNotesPath) { Remove-Item -Path $caseNotesPath -Recurse -Force }

Write-Host "[$TestCaseId] Reset teardown notes."
& $teardownHookPath -ResetOnly -ClientName $ClientName -TestType $TestType -TestCaseId $TestCaseId -WriteTeardownFile $WriteTeardownFile -ExecutionNotesRoot $executionNotesRoot

Write-Host "[$TestCaseId] Run login gatekeeper."
& $loginHookPath -LoginStatus $LoginStatus -ClientName $ClientName -TestType $TestType -TestCaseId $TestCaseId -WriteTeardownFile $WriteTeardownFile -ExecutionNotesRoot $executionNotesRoot -Evidence $Evidence
if ($LASTEXITCODE -ne 0) {
    Write-Host "[$TestCaseId] Stopped after login gatekeeper failure."
    Update-Dashboard
    exit 1
}

Write-Host "[$TestCaseId] Execute test steps from: $TestCaseFile"

if ($TestStatus -eq "Pass") {
    & $teardownHookPath `
        -Status "Pass" `
        -ActualResult "All step-level pass criteria met." `
        -FailedStep "N/A" `
        -Evidence "N/A" `
        -RunSummary "$TestCaseId completed successfully." `
        -WhatWentWrong "N/A" `
        -WhatWorked "Login and workflow steps completed." `
        -Impact "Workflow task configured as expected." `
        -RecommendedNextActions "Proceed to next test case." `
        -ClientName $ClientName `
        -TestType $TestType `
        -TestCaseId $TestCaseId `
        -WriteTeardownFile $WriteTeardownFile `
        -ExecutionNotesRoot $executionNotesRoot

    Write-Host "[$TestCaseId] Completed with Pass."
    Update-Dashboard
    exit 0
}

if ([string]::IsNullOrWhiteSpace($FailedStep)) { $FailedStep = "Unknown test step" }
if ([string]::IsNullOrWhiteSpace($Evidence)) {
    if ($WriteTeardownFile) {
        $Evidence = Join-Path (Join-Path $caseNotesPath "screenshots") "$safeTestCaseId-failure.png"
    } else {
        $Evidence = Join-Path (Join-Path $executionNotesRoot "screenshots") "$safeTestCaseId-failure.png"
    }
}

& $teardownHookPath `
    -Status $TestStatus `
    -ActualResult "Test execution failed or blocked before completion." `
    -FailedStep $FailedStep `
    -Evidence $Evidence `
    -RunSummary "$TestCaseId ended with $TestStatus." `
    -WhatWentWrong "A required step-level pass criterion was not met." `
    -WhatWorked "Teardown captured failure details for triage." `
    -Impact "Test case did not meet completion criteria." `
    -RecommendedNextActions "Fix the failure and rerun $TestCaseId." `
    -ClientName $ClientName `
    -TestType $TestType `
    -TestCaseId $TestCaseId `
    -WriteTeardownFile $WriteTeardownFile `
    -ExecutionNotesRoot $executionNotesRoot

Write-Host "[$TestCaseId] Completed with $TestStatus."
Update-Dashboard
exit 1
