# Teardown

> Template only. Runtime output is written to `AI_AUTOMATION/test-results/<ClientName>-<TestType>/<TestCaseId>/Teardown.md` only when `WriteTeardownFile=true`.

- Status: In Progress
- Actual Result: 
- Failed Step: 
- Evidence: 
- Timestamp:

## Failure Handling
- Take screenshot evidence only when the test fails and cannot proceed further from the failing step.
- For login failure handling and login evidence, use Login.md.
- Stop execution only after a critical failure that blocks further progress.
- Report failure only when execution cannot continue.
- Always report final test results in text (Status, Actual Result, Failed Step, Evidence, Timestamp), even when no screenshot is taken.

## Final Verification
- Mark Status: Pass only if all step-level pass criteria are met.
- Mark Status: Fail if any required step-level pass criterion is not met.

## Run Summary

## What Went Wrong

## What Worked

## Impact

## Recommended Next Actions
