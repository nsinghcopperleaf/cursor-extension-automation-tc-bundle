# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-07

### Added

- VSIX extension that syncs `rules`, `skills`, and `AI_AUTOMATION` (TC001–TC003, shared library) into `%USERPROFILE%\.cursor` on activation.
- Blank `HONI/Workflow/config.json` template; existing user config is not overwritten on later syncs.
- Command Palette action to re-sync without restart.
