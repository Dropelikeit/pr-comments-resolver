---
name: resolve-comments
description: Use when resolving unresolved PR or MR review comments, working through reviewer feedback, or addressing code review threads on GitHub, GitLab, Bitbucket Cloud, or Azure DevOps repositories
---

# Resolve PR/MR Review Comments

Work through all unresolved review comments from a pull request or merge request on GitHub, GitLab, Bitbucket Cloud, or Azure DevOps.

> This skill activates implicitly when its description matches your request. You can also reference it explicitly by name.

## Step 1: Platform Detection & CLI Verification

### 1.1 Check Memory

Check the agent's persistent memory (if available) for a previously saved `pr-comments-resolver-platform` configuration. If found, run a quick auth verification using the recorded `Auth method` and the platform module's `Auth verification` section.

If the memory exists and auth is healthy, skip to Step 1.6 (Load Platform Module).

If the memory is stale (auth fails) or not found, continue with detection.

**Back-compat:** memories from older versions may not contain an `Auth method` field. Treat a missing `Auth method` as `cli`.

### 1.2 Detect Platform

Get the remote URL:

```bash
git remote get-url origin
```

Match the URL against known patterns:

| URL Contains | Platform |
|---|---|
| `github.com` | GitHub |
| `gitlab.com` | GitLab |
| `bitbucket.org` | Bitbucket Cloud |
| `dev.azure.com` or `visualstudio.com` | Azure DevOps |

If the URL does not match any known pattern (e.g., a self-hosted instance), ask the user which platform this repository is hosted on. Offer the options: GitHub, GitLab, Bitbucket Cloud, Azure DevOps, Other. Ask the user directly in chat with the listed options.

If the user picks "Other", inform them: "This skill currently supports GitHub, GitLab, Bitbucket Cloud, and Azure DevOps. Other hosting platforms are not yet supported." Then stop.

### 1.3 Select Auth Method (Bitbucket and Azure only)

For `bitbucket` and `azure`, if memory does not already record an `Auth method`, ask the user which method to use. Ask the user directly in chat with the listed options.

Options:

- **Bitbucket**: `CLI (acli)` or `MCP (Atlassian Remote, OAuth)`.
- **Azure DevOps**: `CLI (az + azure-devops extension)` or `MCP (@azure-devops/mcp, PAT-based)`.

For `github` and `gitlab`, `Auth method` is always `cli` — no prompt is shown.

Remember the chosen value as `Auth method` (it gets written to memory in Step 1.5).

### 1.4 Verify Auth

Use the platform module's `Auth verification` section, following the path that matches the chosen `Auth method` (Path A for `cli`, Path B for `mcp`). If auth is not healthy, follow the module's stop-with-instructions guidance.

### 1.5 Persist Platform (if supported)

Augment reads `AGENTS.md` for project guidelines. To persist platform info across runs, add a `## pr-comments-resolver` section (or place these lines in `AGENTS.local.md` if you want to keep them out of version control):

```
## pr-comments-resolver

- platform: <github|gitlab|bitbucket|azure>
- auth-method: <cli|mcp>
- cli-tool: <gh|glab|acli|az>        # only when auth-method = cli
- mcp-server: <ado|atlassian>        # only when auth-method = mcp
- token-env-var: $<ENV_VAR_NAME>     # only when MCP auth uses a PAT
- org-or-workspace: <name>           # bitbucket workspace or azure organization
- repository: <platform-native identifier>
```

Memories without `auth-method` from older runs are treated as `auth-method: cli`.

### 1.6 Load Platform Module

Read the file `platforms/<platform>.md` (relative to this SKILL.md). It contains the platform-specific instructions for auth verification, repository identifier, PR/MR number detection, comment fetching, posting replies, and resolving threads. Use it as the authoritative source for those operations throughout the rest of this skill.

Platform modules may invoke the MCP Config Writer for setting up an MCP server. The writer's procedure is:

### MCP Config Writer

This adapter does not currently include automatic MCP server configuration support. If a platform module requires MCP setup (Bitbucket MCP via Atlassian Remote, or Azure DevOps MCP via `@azure-devops/mcp`), instruct the user how to configure their host manually:

- Show the user the MCP server entry the platform module wants to add (server id, command, args, and env-var-reference env block).
- Tell them to add it to their adapter's MCP configuration (e.g., Codex / Augment / Junie / Roo configuration file — exact path depends on the user's setup).
- Remind them: never paste a literal PAT into the config. Use the env-variable reference exactly as shown.
- Ask them to confirm when done, then stop and tell them to restart their agent.

### 1.7 Get Repository Identifier

See the platform module's `Repository identifier` section.

## Step 2: Determine PR/MR Number

If `$ARGUMENTS` is provided, use it as the PR/MR number.

If `$ARGUMENTS` is empty or not provided, detect automatically from the current branch. See the platform module's `PR number` (or `MR IID`) section.

If no PR/MR exists for the current branch, ask the user for the PR/MR number. Ask the user directly in chat with the listed options.

## Step 3: Fetch & Display Unresolved Comments

Use the platform module's `Fetch unresolved …` section to obtain the list of unresolved review threads/discussions and map them to the uniform `{file, line, author, body, thread_id}` shape. Then render them via the `Display Unresolved Comments` block below.

### Display Unresolved Comments

Show unresolved comments as a numbered list:

```
## Unresolved PR Comments (X of Y total)

1. **path/to/file.ts:42** - @author
   > Comment text here...

2. **path/to/file.ts:108** - @author (outdated)
   > Another comment...
```

The `(outdated)` marker means the code has changed since the comment was written — check relevance before acting.

If there are no unresolved comments, inform the user and stop.

## Step 4: Create Tasks & Resolve Comments

Track each unresolved comment as a separate work item and address them sequentially.

Then work through each task sequentially:

1. **Read the affected file** at the referenced location
2. **Understand the comment** in the context of the surrounding code
3. If the comment is marked `(outdated)`, check whether the feedback is still relevant before acting
4. **If unclear**: Ask the user what exactly is expected. Ask the user directly in chat with the listed options.
5. **Implement the change** according to the reviewer's feedback
6. **Mark the task as completed**

Important:
- Work through comments sequentially, not in parallel — changes may overlap in the same file
- Follow conventions from AGENTS.md if present in the project
- Respect existing code patterns and architecture in the project

## Step 5: Verification

After all comments have been addressed, run project-defined verification commands.

### 5.1 Find Verification Commands

Check the project's AGENTS.md for defined verification commands (linting, static analysis, tests). Look for sections like "Commands", "Scripts", "Testing", or similar.

Examples of what you might find:
- PHP: `task cs-fixer`, `task psalm`, `task test`
- JavaScript/TypeScript: `npm run lint`, `npm test`
- Python: `ruff check .`, `pytest`
- Go: `go vet ./...`, `go test ./...`

### 5.2 Run Verification

If verification commands are found in AGENTS.md, run them in order.

If no verification commands are found, ask the user (offer a "skip verification" option as well): Ask the user directly in chat with the listed options.
> "What verification commands should I run for this project? (e.g., lint, tests, type checks)"

### 5.3 Fix Issues

If any verification step fails:
1. Analyze the error output
2. Fix the issue
3. Re-run the failing verification command
4. Repeat until all checks pass

## Step 6: Self-Review

Review all changes made:

```bash
git diff
```

Check for:

### Reusability
- Is existing code reused instead of duplicated?
- Are new abstractions justified or unnecessary?

### Code Quality
- Is the code clear and understandable?
- Does it follow existing patterns in the project?

### Security
- No SQL injection, XSS, command injection, or other OWASP Top 10 vulnerabilities?
- Are inputs validated at system boundaries?
- No secrets or sensitive data in the code?

### Project-Specific Conventions
Check any project-specific conventions and patterns defined in the project's AGENTS.md. The checks above are universal — defer to whatever the project documents for language- or framework-specific rules.

If you find issues during self-review, fix them immediately and re-run verification from Step 5.

## Step 7: Summary

Show the user a summary of the work done:

- **Comments addressed**: List each comment with file path, line number, and what was changed
- **Files modified**: List each file with a brief description of changes
- **Verification results**: Which commands ran and their pass/fail status
- **Self-review results**: Any issues found and fixed during self-review
- **Unresolved comments**: If any comments could not be addressed, state the reason (e.g., unclear intent, requires architectural change, blocked by external dependency)
