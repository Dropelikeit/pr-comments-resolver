# Bitbucket and Azure DevOps Platform Support

## Overview

The `resolve-comments` skill currently supports GitHub and GitLab through their respective CLIs (`gh`, `glab`). Users on Bitbucket Cloud and Azure DevOps are blocked entirely: the skill detects those remotes and stops with "support is planned". This feature lifts the block by adding both platforms as first-class targets, each offering two user-selectable authentication paths (a CLI path analogous to the existing `gh`/`glab` flow, and an MCP-server path). The KI-Manager persona — the orchestration role embodied by the skill itself — owns platform detection, auth routing, secret hygiene, and the unified comment-resolution loop.

The value is straightforward: every PR/MR reviewer feedback workflow the skill already automates becomes available to two additional hosting ecosystems, without the user having to learn a different command or copy a separate template per platform.

## User Stories

- As the **KI-Manager**, I detect the platform from the remote URL so I can route work to the correct platform module without asking the user about something I can derive.
- As the **KI-Manager**, I ask the user **once** which authentication method to use for Bitbucket and Azure (CLI vs MCP), then remember the decision in project memory so future invocations skip the prompt.
- As the **KI-Manager**, I never write a secret to disk. Memory files and MCP server configs store only `${ENV_VAR}` references and the env variable's name — never the value.
- As the **KI-Manager**, when I configure an MCP server, I refuse silent mutation: I diff against any existing entry and require explicit user consent (Overwrite / Keep / Abort) before touching the file.
- As a **Bitbucket Cloud user**, I can choose between `acli` (CLI) and the official Atlassian Remote MCP (OAuth) so my team's existing auth setup is respected.
- As an **Azure DevOps user**, I can choose between `az` with the `azure-devops` extension (CLI) and `@azure-devops/mcp` (PAT-based, via env-var reference) so I can match my organisation's tooling.
- As a **GitHub or GitLab user already on a stable setup**, I see no change in behaviour: my existing project memory is read as `Auth method: cli`, no auth prompt appears, and the skill runs exactly as before.
- As a **developer reviewing this codebase**, I can read one platform module (`platforms/<name>.md`) to understand everything about how that platform integrates, without grepping across a single monolithic SKILL.md.

## Acceptance Criteria

- [ ] `git remote get-url origin` containing `bitbucket.org` is detected as `bitbucket`; containing `dev.azure.com` or `visualstudio.com` is detected as `azure`.
- [ ] On a Bitbucket or Azure repository with no `pr-comments-resolver-platform` memory, the orchestrator prompts for an auth method via AskUserQuestion before delegating to the platform module.
- [ ] On a Bitbucket or Azure repository where the memory already records `Auth method`, no auth-method prompt is shown.
- [ ] Choosing **Bitbucket CLI** runs `acli auth status`; missing-CLI and not-authenticated states produce specific user instructions and stop the skill.
- [ ] Choosing **Bitbucket MCP** writes an `mcpServers.atlassian` entry pointing to `https://mcp.atlassian.com/v1/sse` via `npx mcp-remote`, does **not** prompt for a PAT (OAuth), and instructs the user to restart Claude Code.
- [ ] Choosing **Azure CLI** verifies `az --version`, the `azure-devops` extension, and `az account show`; missing pieces produce specific install/login instructions and stop the skill.
- [ ] Choosing **Azure MCP** prompts for the organisation name and the env-variable name (default `AZURE_DEVOPS_PAT`), verifies the env variable is set in the current shell, writes an `mcpServers.ado` entry with `${ENV_VAR}` reference (not the value), and instructs the user to restart Claude Code.
- [ ] The MCP Config Writer asks the user whether to write to user scope (`~/.claude.json`) or project scope (`.mcp.json`).
- [ ] If `mcpServers.<id>` already exists and differs from the entry to be written, the writer presents the diff and asks Overwrite / Keep existing / Abort via AskUserQuestion. No silent overwrite.
- [ ] If the chosen env variable is unset, the skill instructs the user to set it in their shell profile and stops without writing the MCP config.
- [ ] Existing GitHub and GitLab project memories without `Auth method` continue to work — they are treated as `cli`.
- [ ] The generated `skills/resolve-comments/SKILL.md` is the orchestrator only; per-platform content lives in `skills/resolve-comments/platforms/{github,gitlab,bitbucket,azure}.md`.
- [ ] `bash scripts/build.sh all` succeeds for every adapter (claude, codex, augment, junie, roo).
- [ ] `python3 scripts/validate.py` reports zero errors.
- [ ] `bash tests/build_test.sh` prints `PASS`, including new assertions that each platform module exists, is non-empty, contains no unsubstituted `<!-- ADAPTER: -->` placeholders, and includes the expected platform markers (`acli`, `mcp.atlassian.com/v1/sse`, `az repos pr`, `@azure-devops/mcp`, `AZURE_DEVOPS_PAT`).
- [ ] No file under `core/`, `adapters/`, `skills/`, or `dist/` contains a literal-looking token (regex check on Azure module: `PERSONAL_ACCESS_TOKEN` must not be followed by a 20+ character alphanumeric).
- [ ] Plugin manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`) are bumped to `0.3.0` and `CHANGELOG.md` records the additions.

## Non-Goals

- Self-hosted Bitbucket Server or Azure DevOps Server. v1 covers Bitbucket Cloud and Azure DevOps (cloud) only.
- Community-maintained Bitbucket MCP servers. Only the official Atlassian Remote MCP is supported.
- OS keychain or credential-manager integration. Env-var references are sufficient for v1.
- Token lifecycle management: rotation, expiry warnings, scope auditing.
- Migrating existing memories: the schema extension is read-time back-compat only; no rewrite pass.
- Automated end-to-end tests against live Bitbucket or Azure DevOps APIs. Verification is build smoke tests plus manual scenario walkthroughs.
- New SDD persona work beyond KI-Manager.

## Open Questions

None at this time — the open questions raised during brainstorming were resolved before this spec was written (see the design doc's "Open Questions Resolved During Brainstorming" table at `docs/superpowers/specs/2026-05-12-bitbucket-azure-platforms-design.md`).

## Dependencies

- External CLIs (only required for the corresponding CLI path on the corresponding platform): `acli` (Bitbucket), `az` with `azure-devops` extension (Azure).
- External MCP servers (only required for the corresponding MCP path):
  - Atlassian Remote MCP at `https://mcp.atlassian.com/v1/sse` (Bitbucket MCP path)
  - `@azure-devops/mcp` available via `npx` (Azure MCP path)
- Existing project infrastructure: `core/kernel.md`, `core/` adapter snippets, `scripts/build.sh`, `scripts/validate.py`, `scripts/substitute.py`, `tests/build_test.sh`.
- Linked design and plan documents (not in `specs/` because `docs/superpowers/` is the project's brainstorming/planning home and is gitignored):
  - `docs/superpowers/specs/2026-05-12-bitbucket-azure-platforms-design.md` — the approved design.
  - `docs/superpowers/plans/2026-05-12-bitbucket-azure-platforms.md` — the approved implementation plan.
