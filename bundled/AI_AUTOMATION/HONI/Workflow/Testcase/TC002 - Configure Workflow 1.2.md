# TC002 - Configure Workflow 1.2

## Meta
- Test Case ID: TC002
- Priority: High
- Tags: login, Workflow Testing, regression, configuration, investment

## Test Data
- Workflow Entity: Investment
- Workflow 1.1 Name: WF1.1_Investment Feedback - Investment WF
- Workflow 1.2 Name: WF1.2_Investment Feedback with Validate Investment - Investment WF
- Workflow 1.2 Description: WF1.2 investment feedback workflow with Validate Investment step (Investment entity).
- Task 1: Feedback: Send to Investment Owner
- Task 2: Validate Investment
- Task 3: Feedback: Save Reviewer Comments

## Mandatory Hook Policy
- Before executing this test case, execute `../../../library/Login.md`.
- Use login config from `../config.json` when executing `../../../library/Login.md`.
- After completing this test case, execute `../../../library/Teardown.md`.

## Steps
1. Go to the Home page (Pass criteria: the Home page loads successfully).
2. Navigate to System --> Configuration --> Workflow & Approval Processes --> Configure Workflows (Pass criteria: Configure Workflows page loads successfully and shows the Search box).

3. In Configure Workflows, search for `WF1.1_Investment Feedback - Investment WF` (Pass criteria: either the workflow is listed, or the results show it is not present).
4. If `WF1.1_Investment Feedback - Investment WF` exists, verify there is exactly one matching result and open it (Pass criteria: exactly one match is shown; Workflow Definition page loads and the workflow name matches exactly). Do not create a duplicate workflow.
5. If `WF1.1_Investment Feedback - Investment WF` does not exist, create it (Pass criteria: workflow is created successfully with no blocking error):
   - Click Create
   - Set Workflow Entity = Investment
   - Name = `WF1.1_Investment Feedback - Investment WF`
   - Description = `WF1.1 Investment feedback workflow (Investment entity).`
   - Click Save
6. Ensure the workflow `WF1.1_Investment Feedback - Investment WF` has the following Sequence of Tasks (Pass criteria: the Sequence of Tasks table shows the required rows and next actions):
   - Sequence 1: `Feedback: Send to Investment Owner`
     - Success Next Action = Go to Next Task
     - Fail Next Action = Exit With Failed
     - Cancel Next Action = Exit With Failed
     - Expire Next Action = Exit With Failed
   - Sequence 2: `Feedback: Save Reviewer Comments`
     - Success Next Action = Exit With Success
     - Fail Next Action = Exit With Failed
     - Cancel Next Action = Exit With Failed
     - Expire Next Action = (blank / not configurable)

7. Return to Configure Workflows (Pass criteria: Configure Workflows grid is visible).

8. In Configure Workflows, search for `WF1.2_Investment Feedback with Validate Investment - Investment WF` (Pass criteria: either the workflow is listed, or the results show it is not present).
9. If `WF1.2_Investment Feedback with Validate Investment - Investment WF` exists, verify there is exactly one matching result and open it (Pass criteria: exactly one match is shown; Workflow Definition page loads and the workflow name matches exactly). Do not create a duplicate workflow.
10. If `WF1.2_Investment Feedback with Validate Investment - Investment WF` does not exist, create it (Pass criteria: workflow is created successfully with no blocking error):
    - Click Create
    - Set Workflow Entity = Investment
    - Name = `WF1.2_Investment Feedback with Validate Investment - Investment WF`
    - Description = `WF1.2 investment feedback workflow with Validate Investment step (Investment entity).`
    - Click Save
11. Ensure the workflow `WF1.2_Investment Feedback with Validate Investment - Investment WF` has the following Sequence of Tasks (Pass criteria: the Sequence of Tasks table shows the required rows and next actions):
    - Sequence 1: `Feedback: Send to Investment Owner`
      - Success Next Action = Go to Next Task
      - Fail Next Action = Exit With Failed
      - Cancel Next Action = Exit With Failed
      - Expire Next Action = Exit With Failed
    - Sequence 2: `Validate Investment`
      - Success Next Action = Go to Next Task
      - Fail Next Action = Exit With Failed
      - Cancel Next Action = Exit With Failed
      - Expire Next Action = (blank / not configurable)
    - Sequence 3: `Feedback: Save Reviewer Comments`
      - Success Next Action = Exit With Success
      - Fail Next Action = Exit With Failed
      - Cancel Next Action = Exit With Failed
      - Expire Next Action = (blank / not configurable)

12. Save the workflow definition if Save is enabled (Pass criteria: Save completes successfully and Save becomes disabled again).
13. Go to Home page (Pass criteria: Home page loads successfully).

## Expected Results
- `WF1.1_Investment Feedback - Investment WF` exists and has the expected 2-task sequence and next actions.
- `WF1.2_Investment Feedback with Validate Investment - Investment WF` exists and has the expected 3-task sequence and next actions, with `Validate Investment` present as sequence 2.
- No duplicate workflows are created when an exact-name match already exists.

## Notes
- In this application, the Expire Next Action field may be disabled for some tasks (for example `Validate Investment`), and may remain blank by design.
