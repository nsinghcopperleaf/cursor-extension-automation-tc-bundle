# LOGIN - Shared Login Flow

## Purpose
- Reusable login flow for all test cases in this folder.
- Run this file first before executing any test-case specific steps.

## Meta
- Environment: Developement
- Config Source: provided by the active test case (recommended path from test case file: `../config.json`)
- Base URL: from config key `baseUrl`
- Run As: manual-browser-agent
- Tags: login, shared-flow

## Test Data
- Username: from config key `username`
- Password: from config key `password`

## Preconditions
- User account is active
- No MFA prompt for this account
- Site is reachable

## Steps
1. Resolve login config from the active test case path (recommended: sibling `../config.json`).
2. Open base URL from config key `baseUrl`
3. Wait until the Login page is fully visible:
   - Username input is visible
   - Password input is visible
   - Sign In control is visible
4. Enter Username from config key `username`.
   - Preferred: type with clear/replace behavior (not append).
   - If the value does not “stick”, type slowly (character-by-character) and re-check the input value is not empty.
5. Enter Password from config key `password`.
   - Preferred: **fill/replace** behavior (not append). Password fields are sometimes flaky with “type”.
   - If the value does not “stick”, re-focus the Password input and try fill/replace again (then re-check the input value is not empty/masked).
6. Submit login:
   - Preferred: **focus the Password field and press Enter once**.
   - Validation after preferred action:
     - Wait up to 10 seconds for navigation.
     - Confirm URL no longer contains `/Login/UserLogin.aspx`.
   - Fallback A (only if still on login page): **Tab** until the Sign In control is focused, then press **Enter** (or **Space**) once. Wait up to 10 seconds.
   - Fallback B (only if still on login page): click the **Sign In** control once, then wait up to 10 seconds for navigation.
     - Automation note: in this app the “Sign In” control is commonly an `<input type="submit" value="Sign In">`. Some snapshots label it as a “button” role, but automation may treat it as an “input”.
     - If a click fails (stale ref / type mismatch), take a **fresh snapshot** and retry the click.
     - If the element remains hard to click, retry the click with a small offset inside the element (avoid border overlays).
7. Verify URL no longer contains `/Login/UserLogin.aspx`
8. Verify dashboard/home page is visible

## Expected Results
- User logs in successfully
- Dashboard/Home page is visible after login
- No error toast/message is shown during happy path

## Failure Handling
- Take screenshot evidence only when login fails (or at the exact failing step).
- Capture:
  - visible error message text
  - current URL
  - step number where failure happened
- Stop execution after critical failure
- Report the critical failure
- Always report final login result in text (Status, Actual Result, Failed Step, Evidence, Timestamp), even when no screenshot is taken.

## Execution Notes (filled during run)
- Status:
- Actual Result:
- Failed Step:
- Evidence:
- Timestamp:
