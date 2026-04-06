# Rebuild bundled/ from C:\Users\NSingh\.cursor (rules, skills, AI_AUTOMATION TC001-003).
# Does NOT copy test-results. Writes a blank HONI/Workflow/config.json template (no secrets).

$ErrorActionPreference = "Stop"
$ext = $PSScriptRoot
$src = Split-Path $ext -Parent

Remove-Item "$ext\bundled" -Recurse -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path "$ext\bundled\rules" | Out-Null
Copy-Item "$src\rules\*" "$ext\bundled\rules\" -Force
Copy-Item "$src\skills" "$ext\bundled\skills" -Recurse -Force

$bd = "$ext\bundled\AI_AUTOMATION"
New-Item -ItemType Directory -Force -Path "$bd\library" | Out-Null
Copy-Item "$src\AI_AUTOMATION\library\*" "$bd\library\" -Recurse -Force
Remove-Item "$bd\library\winexecution" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$bd\library\DataImport.md" -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$bd\HONI\Workflow\Testcase" | Out-Null

$template = @'
{
  "baseUrl": "",
  "username": "",
  "password": ""
}
'@
Set-Content -Path "$bd\HONI\Workflow\config.json" -Value $template.TrimEnd() -Encoding UTF8

Copy-Item "$src\AI_AUTOMATION\HONI\Workflow\Testcase\TC001*.md" "$bd\HONI\Workflow\Testcase\" -Force
Copy-Item "$src\AI_AUTOMATION\HONI\Workflow\Testcase\TC002*.md" "$bd\HONI\Workflow\Testcase\" -Force
Copy-Item "$src\AI_AUTOMATION\HONI\Workflow\Testcase\TC003*.md" "$bd\HONI\Workflow\Testcase\" -Force

Write-Host "bundled/ rebuilt (no test-results, no library/winexecution or DataImport.md; config.json is empty template)."
