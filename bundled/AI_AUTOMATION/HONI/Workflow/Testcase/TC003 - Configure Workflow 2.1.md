# TC003 - Configure Workflow 2.1

## Meta
- Test Case ID: TC003
- Priority: High
- Tags: login, Workflow Testing, regression, configuration, portfolio

## Test Data
- Target System Entity: Portfolio
- Success Function: Run Workflow On Portfolio Investments
- Workflow Task 2.1 Name: WF2.1_Launch Investment Feedback WF from Portfolio
- Workflow Task 2.2 Name: WF2.2_Launch Investment Feedback with Validate Investment WF from Portfolio
- Investment Workflow (2.1): WF1.1_Investment Feedback - Investment WF
- Investment Workflow (2.2): WF1.2_Investment Feedback with Validate Investment - Investment WF
- Child Portfolios: Enabled
- Run on Child Investments: Enabled

## Mandatory Hook Policy
- Before executing this test case, execute `../../../library/Login.md`.
- Use login config from `../config.json` when executing `../../../library/Login.md`.
- After completing this test case, execute `../../../library/Teardown.md`.

## Steps
1. Go to the Home page (Pass criteria: the Home page loads successfully).
2. Navigate to System --> Configuration --> Workflow & Approval Processes --> Configure Tasks (Pass criteria: Configure Tasks page loads successfully and shows the Search box).

3. Search for `WF2.1_Launch Investment Feedback WF from Portfolio` (Pass criteria: either the task is listed, or the results show it is not present).
4. If `WF2.1_Launch Investment Feedback WF from Portfolio` exists, verify there is exactly one matching result and open it (Pass criteria: exactly one match is shown; Task Definition page loads and the Name matches exactly). Do not create a duplicate task.
5. If `WF2.1_Launch Investment Feedback WF from Portfolio` does not exist, create it (Pass criteria: task is created successfully with no blocking error):
   - Click Create
   - Name = `WF2.1_Launch Investment Feedback WF from Portfolio`
   - Target System Entity = Portfolio
   - Success Function = `Run Workflow On Portfolio Investments`
   - Investment Workflow = `WF1.1_Investment Feedback - Investment WF`
   - Enable `Child Portfolios`
   - Enable `Run on Child Investments`
   - Do not add any rules
   - Click Save
6. Verify the task `WF2.1_Launch Investment Feedback WF from Portfolio` configuration (Pass criteria: all configured values match exactly):
   - Target System Entity = Portfolio
   - Success Function = `Run Workflow On Portfolio Investments`
   - Investment Workflow = `WF1.1_Investment Feedback - Investment WF`
   - `Child Portfolios` is checked
   - `Run on Child Investments` is checked

7. Return to Configure Tasks (Pass criteria: Configure Tasks grid is visible).

8. Search for `WF2.2_Launch Investment Feedback with Validate Investment WF from Portfolio` (Pass criteria: either the task is listed, or the results show it is not present).
9. If `WF2.2_Launch Investment Feedback with Validate Investment WF from Portfolio` exists, verify there is exactly one matching result and open it (Pass criteria: exactly one match is shown; Task Definition page loads and the Name matches exactly). Do not create a duplicate task.
10. If `WF2.2_Launch Investment Feedback with Validate Investment WF from Portfolio` does not exist, create it (Pass criteria: task is created successfully with no blocking error):
    - Click Create
    - Name = `WF2.2_Launch Investment Feedback with Validate Investment WF from Portfolio`
    - Target System Entity = Portfolio
    - Success Function = `Run Workflow On Portfolio Investments`
    - Investment Workflow = `WF1.2_Investment Feedback with Validate Investment - Investment WF`
    - Enable `Child Portfolios`
    - Enable `Run on Child Investments`
    - Do not add any rules
    - Click Save
11. Verify the task `WF2.2_Launch Investment Feedback with Validate Investment WF from Portfolio` configuration (Pass criteria: all configured values match exactly):
    - Target System Entity = Portfolio
    - Success Function = `Run Workflow On Portfolio Investments`
    - Investment Workflow = `WF1.2_Investment Feedback with Validate Investment - Investment WF`
    - `Child Portfolios` is checked
    - `Run on Child Investments` is checked

12. Go to Home page (Pass criteria: Home page loads successfully).

## Expected Results
- `WF2.1_Launch Investment Feedback WF from Portfolio` exists in Configure Tasks and is configured to launch `WF1.1_Investment Feedback - Investment WF` for portfolio investments (including child portfolios and child investments).
- `WF2.2_Launch Investment Feedback with Validate Investment WF from Portfolio` exists in Configure Tasks and is configured to launch `WF1.2_Investment Feedback with Validate Investment - Investment WF` for portfolio investments (including child portfolios and child investments).
- No duplicate workflow tasks are created when an exact-name match already exists.
