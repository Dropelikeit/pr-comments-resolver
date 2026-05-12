# Bitbucket and Azure DevOps Platform Support — Technical Plan

## Technical Approach

The skill source is a Markdown template processed by `scripts/build.sh`: per-adapter frontmatter + prelude + `core/kernel.md` (with `<!-- ADAPTER: <key> -->` placeholders substituted from `adapters/<agent>/snippets/`) → one `SKILL.md` per agent. To support modular per-platform behaviour, we split `core/kernel.md` into a thin orchestrator and four `core/platforms/<name>.md` modules (`github`, `gitlab`, `bitbucket`, `azure`). The build pipeline is extended to substitute and emit each platform module as a separate file alongside `SKILL.md` per agent (`skills/resolve-comments/platforms/` for claude, `dist/<agent>/.../platforms/` for others).

At runtime the orchestrator (a) detects the platform from `git remote get-url origin`, (b) for Bitbucket and Azure prompts the user once for an auth method (CLI vs MCP) and persists the choice in the project-memory file, (c) loads the matching `platforms/<name>.md` and follows its instructions for auth verification, repo identifier extraction, comment fetching, replying, and resolving. A shared `mcp-config-writer.md` adapter snippet provides the read → diff → prompt → write procedure that platform modules invoke when they need to configure an MCP server entry. Secrets are never written to disk: MCP entries use `${ENV_VAR}` placeholders, and memory files persist only the env-variable name.

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Where modularity lives | Both at source (`core/platforms/`) and at runtime output (`skills/resolve-comments/platforms/`) | The spec's user story for code readers expects per-platform files in the deployed artifact, not just at source level. |
| Build pipeline change | Extend `scripts/build.sh` to iterate `core/platforms/*.md` and emit substituted outputs alongside `SKILL.md` | Minimal change: same substitute step, just looped. `validate.py` and `build_test.sh` are extended in lockstep. |
| Auth-method prompt location | Centralised in the orchestrator (kernel) | Platform modules don't need to know whether they're invoked for the first time. Single source of truth for the AskUserQuestion. |
| Bitbucket MCP choice | Official Atlassian Remote MCP (OAuth) | User-approved during brainstorming. OAuth → no PAT prompt for Bitbucket. Asymmetry with Azure is deliberate. |
| Azure MCP secret handling | `${ENV_VAR_NAME}` reference in MCP config; memory persists env-var name only | Constitution §6. Plain-text PAT in the MCP config was the most concerning option the user explicitly rejected. |
| MCP-config conflict policy | Read existing → diff → AskUserQuestion (Overwrite/Keep/Abort) | Silent mutation is the worst failure mode. The diff makes the user the decision-maker. |
| Memory schema migration | Read-time back-compat: missing `Auth method` is treated as `cli`. No rewrite pass. | YAGNI: GH/GL memories don't break, no extra code to maintain. |
| Per-platform-module shape | Prose runbook with section headings (`Auth verification`, `Repository identifier`, `Fetch unresolved …`, `Post reply / resolve thread`) | The contract is conceptual, not interface-typed. Modules are read by an agent following prose, not invoked as functions. |
| Module loading at runtime | The orchestrator instructs the agent to Read `platforms/<platform>.md` | Smaller orchestrator → less context burned for users on the simple paths (GH/GL). |

## Data Model

The single persisted artifact is the project-memory file `pr-comments-resolver-platform`, written by the `persistence-step.md` adapter snippet.

```yaml
---
name: pr-comments-resolver-platform
type: project
---
Platform:       github | gitlab | bitbucket | azure
Auth method:    cli | mcp                              # optional; missing == cli (back-compat)
CLI tool:       gh | glab | acli | az                  # present iff Auth method = cli
MCP server id:  ado | atlassian                        # present iff Auth method = mcp
Token env var:  $AZURE_DEVOPS_PAT                      # present only for Azure MCP (OAuth-based Atlassian MCP needs no PAT)
Org / Workspace: <name>                                # present for bitbucket (workspace) and azure (org); absent for github/gitlab
Repository:     <platform-native identifier>
```

The MCP server config (in `~/.claude.json` or `.mcp.json`) is the second persisted artifact, but it is not owned by this skill's data model — we only mutate it via the MCP Config Writer procedure, with user-approved diffs.

## API Contracts

Per-platform module contract (each `platforms/<name>.md` must answer these conceptual operations through its prose):

| Operation | Output |
|---|---|
| `verify_auth` | Pass / specific instruction-and-stop |
| `setup_auth` | For MCP: invokes MCP Config Writer with a concrete entry. For CLI: produces an install/login instruction. |
| `get_repo_id` | Platform-native repository identifier string |
| `list_unresolved_comments` | Uniform `{file, line, author, body, thread_id}` list filtered to unresolved |
| `post_reply` | Adds a reply to a specific thread |
| `resolve_thread` | Marks a thread resolved |

The orchestrator (kernel) consumes this contract by following the platform module's prose top-to-bottom, in the section order each module presents.

## Implementation Phases

1. **Foundation** — Build-system extension: emit per-platform module files; extend `validate.py` and `tests/build_test.sh` to assert their existence and integrity. No source content moved yet.
2. **Existing-platform extraction** — Move GitHub and GitLab content from `core/kernel.md` into `core/platforms/github.md` and `core/platforms/gitlab.md`. Kernel becomes orchestrator.
3. **Schema & shared infra** — Extend the `persistence-step.md` snippet (memory schema, back-compat). Add the `mcp-config-writer.md` shared snippet.
4. **New platforms** — Bitbucket module (acli + Atlassian MCP), then Azure module (az + @azure-devops/mcp).
5. **Orchestrator wiring** — Centralise the auth-method prompt in the kernel; trim the corresponding subsections out of bitbucket/azure modules.
6. **Polish** — README, CHANGELOG, version bump to 0.3.0; full-adapter build; manual scenario walkthroughs.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| `acli` and `@azure-devops/mcp` surface (subcommand/tool names) may differ from what the module documents | Engineer following the module hits "unknown command" | Modules explicitly call out "exact subcommand verified at execution time" defer-points; the running agent checks against the installed version. |
| Build pipeline change ships before any platform sources exist, leaving empty outputs | False "PASS" or noisy errors | Task 1 commits the loop with zero `core/platforms/*.md` sources, then immediately runs `build_test.sh` and confirms it fails on missing platform files. Task 2 onward lands sources. |
| Concurrent edits to `core/kernel.md` from later tasks step on the orchestrator centralisation | Merge conflicts inside one branch | Auth-method centralisation (Task 8 in the plan, Phase 5 here) deliberately happens **after** the platform modules are written, not before. |
| Adapter divergence — five adapters each need `persistence-step.md` and `mcp-config-writer.md` updates | Inconsistent behaviour per adapter | One subagent per adapter for the snippet updates; checkpoint runs `python3 scripts/validate.py` which validates each adapter's generated outputs. |
| Secret hygiene regression — a future contributor writes a literal PAT into the Azure module while iterating | Token leaks via git | `tests/build_test.sh` includes a regex check rejecting any 20+ alphanumeric run after `PERSONAL_ACCESS_TOKEN`. |
| Existing GH/GL memories in users' environments break on read | Skill stops unexpectedly | Back-compat clause in `persistence-step.md`: missing `Auth method` is treated as `cli`. Scenario 11.8 in the plan verifies this explicitly. |
| Non-claude adapter outputs (`dist/<agent>/`) drift because they're not in the smoke test | Silent breakage for codex/augment/junie/roo users | Final checkpoint runs `bash scripts/build.sh all` + `python3 scripts/validate.py`, which both already walk every adapter. |

## References

- Source design: `docs/superpowers/specs/2026-05-12-bitbucket-azure-platforms-design.md`
- Source implementation plan (richer than this technical plan; SDD tasks.md is derived from it): `docs/superpowers/plans/2026-05-12-bitbucket-azure-platforms.md`
- Constitution: `specs/memory/constitution.md`
