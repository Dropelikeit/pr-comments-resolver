# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Deferred-critical-comments pass: Step 3.5 classifies each unresolved comment as `normal` or `deferred` (security gaps, missing features, cross-file refactors, reviewer-tagged `blocker`/`critical`/`must-fix`) and lets the user edit the proposed split before any work starts.
- Step 4b processes the deferred bucket strictly after all normal items, one at a time. For each item the user picks the workflow: SDD (`[s]`), Brainstorming (`[b]`), plan mode (`[p]`), inline (`[d]`), or skip (`[x]`). Options requiring a skill the current adapter cannot see are shown marked unavailable.
- One-time-per-project Reply/Resolve permission (`a` = post & resolve, `b` = post only, `c` = none) persisted alongside the existing platform memory. Applied uniformly across Step 4, Step 4b, and the no-code-change path.
- Short clarification routine: a single terse question per ambiguity, with an inferred-assumption shortcut when the answer is implied by earlier turns in the same session.
- Two new adapter snippets (`skill-availability`, `classify-confirm`) shipped for all five agents (claude, codex, augment, junie, roo).

### Changed
- `persistence-step.md` snippets gain the `Reply/Resolve permission` field (per-adapter naming). Memories without the field trigger the one-time prompt — fully back-compat.

## [1.0.0] - 2026-05-12

This is a **breaking release** — the source layout split is observable to anyone building from `core/` and the memory schema gained required fields for new platforms (older memories continue to be read as `cli` for back-compat).

### Added
- Bitbucket Cloud platform support via `acli` (CLI) and the official Atlassian Remote MCP server (`https://mcp.atlassian.com/v1/sse`, OAuth-based).
- Azure DevOps platform support via `az` with the `azure-devops` extension (CLI) and the `@azure-devops/mcp` MCP server (PAT-based; secret kept in an env variable, never written to config files).
- Reusable MCP Config Writer snippet with diff-on-conflict semantics: existing `mcpServers.<id>` entries are never silently overwritten.
- Platform memory schema extended with `Auth method`, `MCP server id`, `Token env var` (env-var reference only), and `Org / Workspace`.
- Auth-method selection in the orchestrator kernel: Bitbucket and Azure repositories prompt once for CLI vs MCP and remember the choice.
- Per-platform module files emitted alongside each agent's `SKILL.md` under `platforms/{github,gitlab,bitbucket,azure}.md`.

### Changed
- Source split: `core/kernel.md` is now a thin orchestrator; platform-specific instructions live in `core/platforms/<name>.md`. The build pipeline (`scripts/build.sh`) emits each platform module per agent.
- Detection table in Step 1.2 of the orchestrator no longer lists "CLI Required" since the auth method is platform-specific and user-selectable for Bitbucket and Azure.

### Compatibility
- Existing GitHub and GitLab project memories without `Auth method` continue to work — they are read as `cli`. No migration needed.
- Generated artifacts for non-Claude adapters (codex, augment, junie, roo) now include `platforms/` directories. The Codex adapter intentionally retains no persistence layer; its MCP Config Writer snippet is a stub directing users to configure their host manually.

## [0.2.0] - 2026-05-10

### Added
- Multi-agent support: the `resolve-comments` skill is now generated for Claude Code, Augment, Codex, Junie, and Roo Code from a single agent-neutral kernel (`core/kernel.md`) plus per-agent adapters in `adapters/<agent>/`.
- Marketplace manifests for additional agents: `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json` (Codex), and `.augment-plugin/{plugin,marketplace}.json` (Augment).
- `scripts/build.sh` generates per-agent SKILL.md files into `dist/<agent>/` (and regenerates the canonical Claude `skills/resolve-comments/SKILL.md`).
- `scripts/substitute.py` and `scripts/validate.py` for placeholder substitution and frontmatter / snippet-coverage validation.
- `scripts/install.sh` convenience installer for Junie and Roo Code with `--user` / `--project` scope flags.
- `tests/build_test.sh` smoke test and `.github/workflows/verify-build.yml` CI workflow that asserts no build drift.
- `AGENTS.md` is recognized as a fallback project context file for agents that do not read `CLAUDE.md`.

### Changed
- The Claude `skills/resolve-comments/SKILL.md` is now a build artifact generated from `core/kernel.md` + `adapters/claude/`. Edit the kernel and adapters, not the generated file.
- Existing Claude marketplace install paths (`.claude-plugin/`, `skills/resolve-comments/`) are preserved — no breaking change for current users.

## [0.1.5] - 2026-04-26
### Fixed
- The `README.md` file contained some German sentences, which have now been correctly translated into English.


## [0.1.4] - 2026-04-26

### Fixed
- Corrected version numbers in CHANGELOG.md to match actual git tags (v0.1.0–v0.1.3)

## [0.1.3] - 2026-04-26

### Added
- `icon.png` (256×256) for marketplace display
- `category`, `tags`, `license`, `author.url` fields in `marketplace.json`
- `version`, `icon`, `homepage`, `repository`, `license`, `keywords`, `author.url` fields in `plugin.json`
- Marketplace installation instructions in README (`/plugin marketplace add`)
- `CONTRIBUTING.md` with development setup, conventions, and release process
- `CHANGELOG.md` (initial, later corrected in 0.1.4)

### Changed
- `repository` field in `plugin.json` changed from plain string to structured object

## [0.1.2] - 2026-04-21

### Added
- `PRIVACY.md` documenting plugin data handling and privacy details

## [0.1.1] - 2026-04-20

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

[Unreleased]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.5...v0.2.0
[0.1.5]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/Dropelikeit/pr-comments-resolver/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Dropelikeit/pr-comments-resolver/releases/tag/v0.1.0
