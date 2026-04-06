# TC001 - Configure Workflow Task with Custom Success Function

## Meta
- Test Case ID: TC001
- Priority: High
- Tags: login, Workflow Testing, regression

## Test Data
- Configurable Field: Investment Feedback
- Target System Entity: Investment
- Workflow Task Name: TC001 - Configure Workflow Task with Custom Success Function
- Workflow Task Description: Validate Save Previous Task Comment To Configurable Field for Investment Feedback

## Mandatory Hook Policy
- Before executing this test case, execute `../../../library/Login.md`.
- Use login config from `../config.json` when executing `../../../library/Login.md`.
- After completing this test case, execute `../../../library/Teardown.md`.

## Steps
1. Navigate to System --> Configuration --> Workflow & Approval Process --> Configure Tasks (Pass criteria: Configure Tasks page loads successfully).
2. Click on + Create button (Pass criteria: Add Workflow Task form opens).
3. Verify that Success Function drop down has "Save Previous Task Comment To Configurable Field" available and select it (Pass criteria: option is visible and selected).
4. Verify that there is a required field with drop down selection for the Configurable Field to be used for the Workflow Comments - select "Investment Feedback" (Pass criteria: field is required and selected value is "Investment Feedback").
5. Verify that there are required checkbox selections "Include User" & "Include Timestamp" - select both (Pass criteria: both checkboxes are selected).
6. Select Target System Entity "Investment" (Pass criteria: selected value remains "Investment").
7. Enter Name as "TC001 - Configure Workflow Task with Custom Success Function" and Description as "Validate Save Previous Task Comment To Configurable Field for Investment Feedback" (Pass criteria: required values are accepted with no validation error). Do not use any alternate name.
8. Click Save (Pass criteria: save succeeds with no blocking error and the workflow task is created with selected values).
9. Delete the workflow task created in this test run from Configure Tasks (Pass criteria: the created workflow task is deleted successfully and is no longer listed).
10. Go to home page (Pass criteria: home page loads successfully).
11. Logout (Pass criteria: user is redirected to the login page).
