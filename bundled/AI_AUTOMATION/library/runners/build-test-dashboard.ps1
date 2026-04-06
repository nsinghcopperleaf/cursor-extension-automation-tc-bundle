param(
    [string]$ResultsRoot = "",
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"
$automationRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))

function Get-SafeText {
    param([string]$Text)
    return [System.Net.WebUtility]::HtmlEncode(($Text | Out-String).Trim())
}

function Get-MarkdownValue {
    param(
        [string[]]$Lines,
        [string]$Label
    )

    $pattern = "^- " + [regex]::Escape($Label) + ":\s*(.*)$"
    foreach ($line in $Lines) {
        $m = [regex]::Match($line, $pattern)
        if ($m.Success) {
            return $m.Groups[1].Value.Trim()
        }
    }

    return ""
}

function Convert-ToRelativeHref {
    param(
        [string]$AbsolutePath,
        [string]$FromDirectory
    )

    if ([string]::IsNullOrWhiteSpace($AbsolutePath) -or -not (Test-Path $AbsolutePath)) {
        return ""
    }

    $fullPath = [System.IO.Path]::GetFullPath($AbsolutePath)
    $fullFromDirectory = [System.IO.Path]::GetFullPath($FromDirectory)

    try {
        $fromUri = [System.Uri]::new(($fullFromDirectory.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar))
        $toUri = [System.Uri]::new($fullPath)
        return $fromUri.MakeRelativeUri($toUri).ToString()
    } catch {
        $relative = Split-Path -Leaf $fullPath
        $parts = $relative -split "[\\/]"
        $encodedParts = @()
        foreach ($part in $parts) {
            $encodedParts += [uri]::EscapeDataString($part)
        }

        return ($encodedParts -join "/")
    }
}

function Parse-RunSummary {
    param([string]$Path)

    $lines = Get-Content -Path $Path
    $tests = @()

    foreach ($line in $lines) {
        $testMatch = [regex]::Match($line, "^- ([^:]+):\s*(Pass|Fail|Blocked)\s*\((.*)\)\s*$", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($testMatch.Success) {
            $tests += [PSCustomObject]@{
                TestCaseId = $testMatch.Groups[1].Value.Trim()
                Status = $testMatch.Groups[2].Value.Trim()
                File = $testMatch.Groups[3].Value.Trim()
            }
        }
    }

    return [PSCustomObject]@{
        Path = $Path
        FileName = Split-Path -Leaf $Path
        Timestamp = Get-MarkdownValue -Lines $lines -Label "Timestamp"
        OverallStatus = Get-MarkdownValue -Lines $lines -Label "Overall Status"
        Total = Get-MarkdownValue -Lines $lines -Label "Total"
        Passed = Get-MarkdownValue -Lines $lines -Label "Passed"
        Failed = Get-MarkdownValue -Lines $lines -Label "Failed"
        Ignored = Get-MarkdownValue -Lines $lines -Label "Ignored"
        Tests = $tests
    }
}

function Parse-Teardown {
    param([string]$Path)

    $lines = Get-Content -Path $Path
    return [PSCustomObject]@{
        Path = $Path
        TestCaseId = Get-MarkdownValue -Lines $lines -Label "Test Case"
        Status = Get-MarkdownValue -Lines $lines -Label "Status"
        Timestamp = Get-MarkdownValue -Lines $lines -Label "Timestamp"
        ActualResult = Get-MarkdownValue -Lines $lines -Label "Actual Result"
    }
}

function Get-StatusClass {
    param([string]$Status)

    $normalized = ""
    if (-not [string]::IsNullOrWhiteSpace($Status)) {
        $normalized = $Status.ToLowerInvariant()
    }

    switch ($normalized) {
        "pass" { return "pass" }
        "fail" { return "fail" }
        "blocked" { return "blocked" }
        "ignored" { return "ignored" }
        default { return "unknown" }
    }
}

if ([string]::IsNullOrWhiteSpace($ResultsRoot)) {
    $ResultsRoot = Join-Path $automationRoot "test-results"
}

if (-not (Test-Path $ResultsRoot)) {
    New-Item -ItemType Directory -Path $ResultsRoot -Force | Out-Null
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $PSScriptRoot "dashboard.html"
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$namespaceDirs = Get-ChildItem -Path $ResultsRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "-ALL$" } | Sort-Object Name
$testRows = @()
$runRows = @()

foreach ($namespaceDir in $namespaceDirs) {
    $summaries = Get-ChildItem -Path $namespaceDir.FullName -File -Filter "run-summary.md" -ErrorAction SilentlyContinue
    $latestSummary = $null

    if ($summaries.Count -gt 0) {
        $parsedSummaries = @()
        foreach ($summaryFile in $summaries) {
            $summary = Parse-RunSummary -Path $summaryFile.FullName
            $parsedSummaries += $summary
            $runRows += [PSCustomObject]@{
                Namespace = $namespaceDir.Name
                Timestamp = if ([string]::IsNullOrWhiteSpace($summary.Timestamp)) { "N/A" } else { $summary.Timestamp }
                Overall = if ([string]::IsNullOrWhiteSpace($summary.OverallStatus)) { "N/A" } else { $summary.OverallStatus }
                Total = if ([string]::IsNullOrWhiteSpace($summary.Total)) { "N/A" } else { $summary.Total }
                Passed = if ([string]::IsNullOrWhiteSpace($summary.Passed)) { "N/A" } else { $summary.Passed }
                Failed = if ([string]::IsNullOrWhiteSpace($summary.Failed)) { "N/A" } else { $summary.Failed }
                Ignored = if ([string]::IsNullOrWhiteSpace($summary.Ignored)) { "N/A" } else { $summary.Ignored }
                SummaryPath = $summary.Path
                SummaryFileName = $summary.FileName
            }
        }

        if ($parsedSummaries.Count -gt 0) {
            $latestSummary = $parsedSummaries[0]
        }
    }

    if ($latestSummary -ne $null -and $latestSummary.Tests.Count -gt 0) {
        foreach ($test in $latestSummary.Tests) {
            $teardownPath = Join-Path (Join-Path $namespaceDir.FullName $test.TestCaseId) "execution-result.md"
            $teardown = $null
            if (Test-Path $teardownPath) {
                $teardown = Parse-Teardown -Path $teardownPath
            }

            $effectiveStatus = if ($teardown -and -not [string]::IsNullOrWhiteSpace($teardown.Status)) { $teardown.Status } else { $test.Status }
            $effectiveTimestamp = if ($teardown -and -not [string]::IsNullOrWhiteSpace($teardown.Timestamp)) { $teardown.Timestamp } else { $latestSummary.Timestamp }

            $testRows += [PSCustomObject]@{
                Namespace = $namespaceDir.Name
                TestCaseId = $test.TestCaseId
                Status = $effectiveStatus
                Timestamp = if ([string]::IsNullOrWhiteSpace($effectiveTimestamp)) { "N/A" } else { $effectiveTimestamp }
                SourceFile = $test.File
                SummaryPath = $latestSummary.Path
                TeardownPath = if (Test-Path $teardownPath) { $teardownPath } else { "" }
            }
        }
    $teardownFiles = Get-ChildItem -Path $namespaceDir.FullName -Recurse -File -Filter "execution-result.md" -ErrorAction SilentlyContinue
    foreach ($teardownFile in $teardownFiles) {
        $testcaseId = Split-Path -Leaf (Split-Path -Parent $teardownFile.FullName)
        
        $isInSummary = $false
        if ($latestSummary -ne $null -and $latestSummary.Tests.Count -gt 0) {
            foreach ($test in $latestSummary.Tests) {
                if ($test.TestCaseId -eq $testcaseId) {
                    $isInSummary = $true
                    break
                }
            }
        }
        
        if (-not $isInSummary) {
            $teardown = Parse-Teardown -Path $teardownFile.FullName
            $testRows += [PSCustomObject]@{
                Namespace = $namespaceDir.Name
                TestCaseId = if ([string]::IsNullOrWhiteSpace($teardown.TestCaseId)) { $testcaseId } else { $teardown.TestCaseId }
                Status = if ([string]::IsNullOrWhiteSpace($teardown.Status)) { "Unknown" } else { $teardown.Status }
                Timestamp = if ([string]::IsNullOrWhiteSpace($teardown.Timestamp)) { "N/A" } else { $teardown.Timestamp }
                SourceFile = "N/A"
                SummaryPath = ""
                TeardownPath = $teardownFile.FullName
            }
        }
    }
}
}

$totalTests = $testRows.Count
$passCount = @($testRows | Where-Object { $_.Status -eq "Pass" }).Count
$failCount = @($testRows | Where-Object { $_.Status -eq "Fail" }).Count
$blockedCount = @($testRows | Where-Object { $_.Status -eq "Blocked" }).Count
$ignoredCount = @($testRows | Where-Object { $_.Status -eq "Ignored" }).Count
$unknownCount = $totalTests - ($passCount + $failCount + $blockedCount + $ignoredCount)
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$namespaceOptions = "<option value='all'>All Namespaces</option>"
foreach ($namespace in ($namespaceDirs.Name | Sort-Object)) {
    $namespaceOptions += "<option value='" + (Get-SafeText $namespace) + "'>" + (Get-SafeText $namespace) + "</option>"
}

$testRowsHtml = ""
if ($testRows.Count -eq 0) {
    $testRowsHtml = "<tr><td colspan='6'>No test results found yet.</td></tr>"
} else {
    foreach ($row in ($testRows | Sort-Object Namespace, TestCaseId)) {
        $statusClass = Get-StatusClass -Status $row.Status
        
        $runDetailLink = "N/A"
        if (-not [string]::IsNullOrWhiteSpace($row.TeardownPath)) {
            $runDetailHref = Convert-ToRelativeHref -AbsolutePath $row.TeardownPath -FromDirectory $outputDirectory
            if (-not [string]::IsNullOrWhiteSpace($runDetailHref)) {
                $runDetailLink = "<a href='$runDetailHref' target='_blank' rel='noopener noreferrer'>Run Detail</a>"
            }
        }

        $searchText = (($row.TestCaseId + " " + $row.SourceFile + " " + $row.Namespace).ToLowerInvariant())

        $testRowsHtml += "<tr data-namespace='" + (Get-SafeText $row.Namespace) + "' data-status='" + (Get-SafeText $statusClass) + "' data-search='" + (Get-SafeText $searchText) + "'>"
        $testRowsHtml += "<td>" + (Get-SafeText $row.Namespace) + "</td>"
        $testRowsHtml += "<td>" + (Get-SafeText $row.TestCaseId) + "</td>"
        $testRowsHtml += "<td><span class='badge $statusClass'>" + (Get-SafeText $row.Status) + "</span></td>"
        $testRowsHtml += "<td>" + (Get-SafeText $row.Timestamp) + "</td>"
        $testRowsHtml += "<td>" + (Get-SafeText $row.SourceFile) + "</td>"
        $testRowsHtml += "<td>$runDetailLink</td>"
        $testRowsHtml += "</tr>"
    }
}

$runRowsHtml = ""
if ($runRows.Count -eq 0) {
    $runRowsHtml = "<tr><td colspan='8'>No run summaries found yet.</td></tr>"
} else {
    foreach ($run in ($runRows | Sort-Object Namespace, Timestamp -Descending)) {
        $statusClass = Get-StatusClass -Status $run.Overall
        $summaryHref = Convert-ToRelativeHref -AbsolutePath $run.SummaryPath -FromDirectory $outputDirectory
        $summaryLink = if ([string]::IsNullOrWhiteSpace($summaryHref)) { "N/A" } else { "<a href='$summaryHref' target='_blank' rel='noopener noreferrer'>Summary</a>" }

        $runRowsHtml += "<tr>"
        $runRowsHtml += "<td>" + (Get-SafeText $run.Namespace) + "</td>"
        $runRowsHtml += "<td>" + (Get-SafeText $run.Timestamp) + "</td>"
        $runRowsHtml += "<td><span class='badge $statusClass'>" + (Get-SafeText $run.Overall) + "</span></td>"
        $runRowsHtml += "<td>" + (Get-SafeText $run.Total) + "</td>"
        $runRowsHtml += "<td>" + (Get-SafeText $run.Passed) + "</td>"
        $runRowsHtml += "<td>" + (Get-SafeText $run.Failed) + "</td>"
        $runRowsHtml += "<td>" + (Get-SafeText $run.Ignored) + "</td>"
        $runRowsHtml += "<td>$summaryLink</td>"
        $runRowsHtml += "</tr>"
    }
}

$html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Test Explorer Dashboard</title>
  <style>
    :root {
      --bg: #0f172a;
      --card: #111827;
      --muted: #94a3b8;
      --text: #e5e7eb;
      --line: #1f2937;
      --pass: #16a34a;
      --fail: #dc2626;
      --blocked: #d97706;
      --unknown: #475569;
      --accent: #2563eb;
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: Segoe UI, Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(180deg, #0b1222 0%, var(--bg) 100%);
      color: var(--text);
    }

    .wrap {
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }

    h1 {
      margin: 0 0 8px;
      font-size: 28px;
      letter-spacing: 0.2px;
    }

    .meta {
      color: var(--muted);
      margin-bottom: 16px;
    }

    .cards {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
      gap: 10px;
      margin-bottom: 16px;
    }

    .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 10px;
      padding: 12px;
    }

    .card .label {
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.4px;
      margin-bottom: 6px;
    }

    .card .value {
      font-size: 22px;
      font-weight: 600;
    }

    .toolbar {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 10px;
      padding: 12px;
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-bottom: 14px;
    }

    .toolbar label {
      font-size: 12px;
      color: var(--muted);
      display: block;
      margin-bottom: 4px;
    }

    .toolbar .control {
      min-width: 190px;
    }

    select, input {
      width: 100%;
      background: #0b1222;
      color: var(--text);
      border: 1px solid #334155;
      border-radius: 8px;
      padding: 8px 10px;
      outline: none;
    }

    select:focus, input:focus {
      border-color: var(--accent);
    }

    .panel {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 10px;
      overflow: hidden;
      margin-bottom: 16px;
    }

    .panel h2 {
      margin: 0;
      padding: 12px 14px;
      border-bottom: 1px solid var(--line);
      font-size: 16px;
    }

    table {
      width: 100%;
      border-collapse: collapse;
    }

    th, td {
      padding: 10px 12px;
      border-bottom: 1px solid var(--line);
      text-align: left;
      vertical-align: top;
      font-size: 13px;
    }

    th {
      color: #cbd5e1;
      font-weight: 600;
      background: #0b1222;
      position: sticky;
      top: 0;
    }

    tr:hover td {
      background: rgba(37, 99, 235, 0.08);
    }

    .badge {
      display: inline-block;
      border-radius: 999px;
      padding: 2px 10px;
      font-size: 12px;
      font-weight: 600;
      color: #fff;
      line-height: 18px;
    }

    .badge.pass { background: var(--pass); }
    .badge.fail { background: var(--fail); }
    .badge.blocked { background: var(--blocked); }
    .badge.ignored { background: #6b7280; }
    .badge.unknown { background: var(--unknown); }

    a {
      color: #93c5fd;
      text-decoration: none;
    }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Test Explorer Dashboard</h1>
    <div class="meta">Generated: $generatedAt | Root: $(Get-SafeText $ResultsRoot)</div>

    <div class="cards">
      <div class="card"><div class="label">Total Tests</div><div class="value">$totalTests</div></div>
      <div class="card"><div class="label">Passed</div><div class="value">$passCount</div></div>
      <div class="card"><div class="label">Failed</div><div class="value">$failCount</div></div>
      <div class="card"><div class="label">Blocked</div><div class="value">$blockedCount</div></div>
      <div class="card"><div class="label">Ignored</div><div class="value">$ignoredCount</div></div>
      <div class="card"><div class="label">Unknown</div><div class="value">$unknownCount</div></div>
    </div>

    <div class="toolbar">
      <div class="control">
        <label for="namespaceFilter">Namespace</label>
        <select id="namespaceFilter">
          $namespaceOptions
        </select>
      </div>
      <div class="control">
        <label for="statusFilter">Status</label>
        <select id="statusFilter">
          <option value="all">All</option>
          <option value="pass">Pass</option>
          <option value="fail">Fail</option>
          <option value="blocked">Blocked</option>
          <option value="ignored">Ignored</option>
          <option value="unknown">Unknown</option>
        </select>
      </div>
      <div class="control" style="flex: 1 1 300px;">
        <label for="searchFilter">Search</label>
        <input id="searchFilter" type="text" placeholder="Test case id, file, namespace">
      </div>
    </div>

    <div class="panel">
      <h2>Latest Test Status</h2>
      <table>
        <thead>
          <tr>
            <th>Namespace</th>
            <th>Test Case</th>
            <th>Status</th>
            <th>Timestamp</th>
            <th>Source File</th>
            <th>Run Detail</th>
          </tr>
        </thead>
        <tbody id="testsTable">
          $testRowsHtml
        </tbody>
      </table>
    </div>

    <div class="panel">
      <h2>Run History</h2>
      <table>
        <thead>
          <tr>
            <th>Namespace</th>
            <th>Timestamp</th>
            <th>Overall</th>
            <th>Total</th>
            <th>Passed</th>
            <th>Failed</th>
            <th>Ignored</th>
            <th>Summary</th>
          </tr>
        </thead>
        <tbody>
          $runRowsHtml
        </tbody>
      </table>
    </div>
  </div>

  <script>
    const namespaceFilter = document.getElementById('namespaceFilter');
    const statusFilter = document.getElementById('statusFilter');
    const searchFilter = document.getElementById('searchFilter');
    const rows = Array.from(document.querySelectorAll('#testsTable tr'));

    function applyFilters() {
      const ns = namespaceFilter.value.toLowerCase();
      const st = statusFilter.value.toLowerCase();
      const q = searchFilter.value.trim().toLowerCase();

      rows.forEach((row) => {
        const rowNs = (row.dataset.namespace || '').toLowerCase();
        const rowSt = (row.dataset.status || '').toLowerCase();
        const rowSearch = (row.dataset.search || '').toLowerCase();

        const nsOk = (ns === 'all') || (rowNs === ns);
        const stOk = (st === 'all') || (rowSt === st);
        const qOk = !q || rowSearch.includes(q);

        row.style.display = (nsOk && stOk && qOk) ? '' : 'none';
      });
    }

    namespaceFilter.addEventListener('change', applyFilters);
    statusFilter.addEventListener('change', applyFilters);
    searchFilter.addEventListener('input', applyFilters);
  </script>
</body>
</html>
"@

Set-Content -Path $OutputPath -Value $html -Encoding UTF8
Write-Host "Dashboard written to: $OutputPath"
$OutputPath
