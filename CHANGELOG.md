# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2026-04-26

### Added
- `icon.png` (256×256) for marketplace display
- `category`, `tags`, `license`, `author.url` fields in `marketplace.json`
- `version`, `icon`, `homepage`, `repository`, `license`, `keywords`, `author.url` fields in `plugin.json`
- Marketplace installation instructions in README (`/plugin marketplace add`)

### Changed
- `repository` in `marketplace.json` changed from plain string to structured object in `plugin.json`

## [0.1.1] - 2026-04-21

### Added
- `PRIVACY.md` documenting plugin data handling and privacy details

### Fixed
- Corrected author name and version in plugin manifests

## [0.1.0] - 2026-04-20

### Added
- Initial release of the `resolve-comments` skill
- Platform detection from git remote URL (GitHub / GitLab)
- CLI verification (`gh` / `glab`) with authentication check
- Auto-detection of PR/MR number from current branch
- Fetching unresolved review comments via GitHub GraphQL and GitLab REST API
- Sequential comment resolution with task tracking
- Configurable verification step reading commands from `CLAUDE.md`
- Self-review step for code quality and security
- Summary step with list of resolved comments
- GitHub workflows for PR labeling, auto-assign, and releases
- `CLAUDE.md` development guide and conventions
- `README.md` with installation, usage, and platform support

[Unreleased]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Dropelikeit/pr-comments-resolver/releases/tag/v0.1.0
