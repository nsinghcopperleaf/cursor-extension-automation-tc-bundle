param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Pass", "Fail", "Blocked", "Ignored")]
    [string]$LoginStatus,
    [string]$TestCaseId = "TC001",
    [string]$ClientName = "HONI",
    [string]$TestType = "Workflow",
    [string]$LoginSkillPath = "",
    [string]$TeardownHookPath = (Join-Path $PSScriptRoot "teardown-hook.ps1"),
    [string]$ExecutionNotesRoot = "",
    [bool]$WriteTeardownFile = $false,
    [string]$Evidence = ""
)

$ErrorActionPreference = "Stop"
$automationRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))

if ([string]::IsNullOrWhiteSpace($LoginSkillPath)) {
    $LoginSkillPath = Join-Path $automationRoot "library/Login.md"
}

if (-not (Test-Path $TeardownHookPath)) { throw "Teardown hook file not found: $TeardownHookPath" }

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
$safeTestCaseId = Get-SafeFolderName -Name $TestCaseId

Write-Host "Login hook started. Login source: $LoginSkillPath"

if ($LoginStatus -eq "Pass") {
    Write-Host "Login hook passed. Continue to test steps."
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Evidence)) {
    if ($WriteTeardownFile) {
        $Evidence = Join-Path (Join-Path (Join-Path $ExecutionNotesRoot $safeTestCaseId) "screenshots") "$safeTestCaseId-login-failure.png"
    } else {
        $Evidence = Join-Path (Join-Path $ExecutionNotesRoot "screenshots") "$safeTestCaseId-login-failure.png"
    }
}

& $TeardownHookPath `
    -Status "Fail" `
    -ActualResult "Login gatekeeper failed. Test execution blocked." `
    -FailedStep "Login hook" `
    -Evidence $Evidence `
    -RunSummary "Login failed before test steps started." `
    -WhatWentWrong "Login did not meet gatekeeper requirements." `
    -WhatWorked "Teardown hook recorded failure context." `
    -Impact "Test case did not continue to business-flow steps." `
    -RecommendedNextActions "Fix login failure and rerun the test." `
    -ClientName $ClientName `
    -TestType $TestType `
    -TestCaseId $TestCaseId `
    -WriteTeardownFile $WriteTeardownFile `
    -ExecutionNotesRoot $ExecutionNotesRoot

Write-Host "Login hook failed. Teardown updated."
exit 1
