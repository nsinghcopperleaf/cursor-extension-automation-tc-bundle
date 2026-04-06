---
name: automation-execution
description: Executes requested test cases and browser automation end-to-end with minimal prompts. Use when the user asks to run test cases, execute TC files, perform browser automation steps, or validate pass/fail criteria.
---

# Automation Execution

## Default behavior
- Execute immediately after a clear run request.
- If asked to re-run a test case, ALWAYS execute it fully again from the beginning, even if it has previously passed. Do not skip execution.
- NEVER fake a test execution by just calling the `.ps1` reporting wrappers in the terminal and assuming a "Pass". You MUST use your browser automation tools to physically open the browser, perform the UI steps, and validate criteria.
- Only AFTER genuinely completing the browser steps should you call the `teardown-hook.ps1` script to log your actual findings into the dashboard. When calling `teardown-hook.ps1`, pass your full step-by-step markdown output into the `-ActualResult` parameter (e.g. by using a PowerShell here-string `@"..."@`) so that the detailed step logs appear inside the generated `execution-result.md` file.
- Do not ask repeated confirmation questions.
- Ask questions only for hard blockers:
  - Missing credentials/access
  - Conflicting instructions
  - Risky/destructive action
- Provide short progress updates during longer runs.
- Return a final step-by-step pass/fail report.

## Testcase workflow
1. Read the testcase file and required hook files.
2. Check for ignore flags in the testcase file (`- Ignore: true` or `- Status: Ignored` under `## Meta`). If found, skip execution and report as Ignored.
3. Run mandatory pre-hooks first (for example login).
4. Execute each step and validate pass criteria.
5. If a step fails to execute or does not pass criteria at any point: STOP proceeding with the test. Do not try to force it to continue. Immediately clean up/delete any data created during the current test run (if any), mark the test as Fail, capture evidence, and run the teardown.
6. If a cleanup/delete step exists, perform it in the same run.
7. Run mandatory post-hooks (for example teardown).
8. Report:
   - Overall status
   - Failed step (if any)
   - Actual result summary
   - Evidence reference (only when failure evidence is required)
9. Automatically open the updated dashboard in the user's browser by running the following command in the terminal (works for any Windows user — uses their profile): `Start-Process (Join-Path $env:USERPROFILE '.cursor\AI_AUTOMATION\library\runners\dashboard.html')`

## Browser workflow
1. Reuse an existing tab when possible.
2. Capture a snapshot before interactions that need element references.
3. Use short waits with checks instead of one long wait.
4. Unlock browser when browser operations are complete.

## Output format
Use this structure:

```markdown
Status: Pass | Fail
Test Case: <id or filename>

Step Results:
1) <step> - Pass/Fail - <short actual result>
2) <step> - Pass/Fail - <short actual result>

Failure:
- Failed Step: <number or N/A>
- Evidence: <screenshot/path or N/A>

Final:
- Cleanup/Teardown: Done/Skipped
- Notes: <short note>
```
