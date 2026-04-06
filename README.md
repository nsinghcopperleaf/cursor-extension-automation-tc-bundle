# Cursor Automation TC bundle (VSIX)

**Source:** [github.com/nsinghcopperleaf/cursor-extension-automation-tc-bundle](https://github.com/nsinghcopperleaf/cursor-extension-automation-tc-bundle) · **Releases:** [download `.vsix`](https://github.com/nsinghcopperleaf/cursor-extension-automation-tc-bundle/releases)

Install this VSIX in **Cursor** or VS Code. On startup it copies into your user folder:

- `.cursor/rules` (from bundle)
- `.cursor/skills` (from bundle)
- `.cursor/AI_AUTOMATION` — **library** (`runners/`, `Login.md`, `Teardown.md` only; **not** `winexecution/` or `DataImport.md`), **HONI/Workflow** with **Testcase** files for **TC001–TC003**, **`Testdata/`** (workflow importer files you place there), and a **blank** `config.json` template

**`test-results` is not shipped**; it is created when you run tests.

## Credentials (`config.json`)

After install, edit:

`%USERPROFILE%\.cursor\AI_AUTOMATION\HONI\Workflow\config.json`

Set `baseUrl`, `username`, and `password` for your environment.

**First-time sync** copies the empty template. **Later syncs do not overwrite** that file if it already exists, so your credentials stay put.

Run command **“HONI Bundle: Sync …”** from the Command Palette to sync again without restarting.

**Note:** Sync merges files into existing folders; it does not delete other test cases already on disk.

## Rebuild `bundled/` (maintainers)

Extension source folder on disk: **`%USERPROFILE%\.cursor\Cursor-ExtensionAutomation-Tc-bundle-0.1.0`** (open this folder in Cursor to edit the extension).

From this folder:

```powershell
.\populate-bundled.ps1
npm run package-vsix
```

Output file: **`Cursor-ExtensionAutomation-Tc-bundle-<version>.vsix`**, where **`<version>`** comes from **`package.json`** → `"version"` (no manual rename).

## Versioning and releases (maintainers)

Use **[Semantic Versioning](https://semver.org/)** (`MAJOR.MINOR.PATCH`):

| Change type | Example | Bump with |
|-------------|---------|-----------|
| Bug fixes, small bundle tweaks | `0.1.0` → `0.1.1` | `npm version patch` |
| New test cases / features, backward compatible | `0.1.0` → `0.2.0` | `npm version minor` |
| Breaking changes to layout or sync behavior | `0.1.0` → `1.0.0` | `npm version major` |

**Release checklist**

1. Update **`CHANGELOG.md`** under a new `## [x.y.z] - YYYY-MM-DD` section.
2. From the extension folder, bump version (updates `package.json` and creates a git commit + tag if this folder is a git repo):
   ```powershell
   cd C:\Users\NSingh\.cursor\Cursor-ExtensionAutomation-Tc-bundle-0.1.0
   npm version patch   # or minor / major
   ```
3. Refresh the bundle if sources changed: `.\populate-bundled.ps1`
4. Build the VSIX (filename picks up the new version automatically):
   ```powershell
   $env:npm_config_registry = "https://registry.npmjs.org/"   # if your npm default registry blocks npx
   npm run package-vsix
   ```
5. **`git push`** and **`git push --tags`**
6. On GitHub ([Releases](https://github.com/nsinghcopperleaf/cursor-extension-automation-tc-bundle/releases)): **New release** → choose tag **`v0.1.1`** (etc.) → attach **`Cursor-ExtensionAutomation-Tc-bundle-x.y.z.vsix`**.

**Note:** The folder name `Cursor-ExtensionAutomation-Tc-bundle-0.1.0` does not need to change when you bump versions; only `package.json` and the `.vsix` name matter for users.

### Packaging without a project `.npmrc`

This repo does **not** include `.npmrc`. If your machine’s default npm registry is a private mirror (for example Artifactory) and `npm run package-vsix` fails with **401**, run once per session:

```powershell
$env:npm_config_registry = "https://registry.npmjs.org/"
npm run package-vsix
```

That only affects the current terminal; it is not stored in the repo.

### End users (installing the VSIX)

New users **only** need the latest **`Cursor-ExtensionAutomation-Tc-bundle-<version>.vsix`** from the [**Releases**](https://github.com/nsinghcopperleaf/cursor-extension-automation-tc-bundle/releases) page (or a shared drive). Install in Cursor (double-click if `.vsix` opens with Cursor, or **Extensions: Install from VSIX…**). On startup the extension copies **rules**, **skills**, and **AI_AUTOMATION** into **`%USERPROFILE%\.cursor`**. They then fill **`config.json`** and configure **Browser MCP** (or their own browser tools) separately — npm is **not** required to use the extension.
