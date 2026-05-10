---
name: resolve-comments
description: Use when resolving unresolved PR or MR review comments, working through reviewer feedback, or addressing code review threads on GitHub or GitLab repositories
---

# Resolve PR/MR Review Comments

Work through all unresolved review comments from a pull request (GitHub) or merge request (GitLab).

> Invoke this skill via `$resolve-comments` or the `/skills` command. This skill is stateless: platform detection runs on every invocation.

## Step 1: Platform Detection & CLI Verification

### 1.1 Check Memory

Check the agent's persistent memory (if available) for a previously saved `pr-comments-resolver-platform` configuration. If found, run a quick CLI auth verification:

- **GitHub**: `gh auth status`
- **GitLab**: `glab auth status`

If the memory exists and the CLI is authenticated, skip to Step 1.5.

If the memory is stale (CLI not authenticated) or not found, continue with detection.

### 1.2 Detect Platform

Get the remote URL:

```bash
git remote get-url origin
```

Match the URL against known patterns:

| URL Contains | Platform | CLI Required |
|---|---|---|
| `github.com` | GitHub | `gh` |
| `gitlab.com` | GitLab | `glab` |
| `dev.azure.com` or `visualstudio.com` | Azure DevOps | Not supported in v1 |

If the URL does not match any known pattern (e.g., a self-hosted instance), ask the user which platform this repository is hosted on. Offer the options: GitHub, GitLab, Other. Ask the user directly in chat with the listed options.

If the platform is Azure DevOps or Other, inform the user:
> "This skill currently supports GitHub and GitLab. Azure DevOps support is planned for a future version."

Then stop.

### 1.3 Verify CLI

Run the appropriate auth check:

- **GitHub**: `gh auth status`
- **GitLab**: `glab auth status`

If the CLI tool is not installed, tell the user:
- GitHub: "Install the GitHub CLI: https://cli.github.com/ — then run `gh auth login`"
- GitLab: "Install the GitLab CLI: https://gitlab.com/gitlab-org/cli — then run `glab auth login`"

If installed but not authenticated, tell the user the exact auth command to run. Then stop.

### 1.4 Persist Platform (if supported)

Codex has no persistent memory layer for skills. Skip persistence — platform detection re-runs on every invocation.

### 1.5 Get Repository Identifier

- **GitHub**:
```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

- **GitLab**:
```bash
glab repo view --output json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['full_name'])"
```

## Step 2: Determine PR/MR Number

If `$ARGUMENTS` is provided, use it as the PR/MR number.

If `$ARGUMENTS` is empty or not provided, detect automatically from the current branch:

- **GitHub**:
```bash
gh pr view --json number,title --jq '"\(.number) \(.title)"'
```

- **GitLab**:
```bash
glab mr view --output json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['iid'], d['title'])"
```

If no PR/MR exists for the current branch, ask the user for the PR/MR number. Ask the user directly in chat with the listed options.

## Step 3: Fetch & Display Unresolved Comments

### GitHub

Load all review threads via the GraphQL API. The `isResolved` status is only available through GraphQL.

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      title
      url
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          path
          line
          startLine
          comments(first: 50) {
            nodes {
              author { login }
              body
              createdAt
              url
            }
          }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=PR_NUMBER
```

Replace `OWNER`, `REPO`, and `PR_NUMBER` with values from Steps 1 and 2.

Filter: keep only threads where `isResolved` is `false`.

### GitLab

Fetch all discussions for the merge request:

```bash
glab api "projects/:id/merge_requests/MR_IID/discussions"
```

Replace `MR_IID` with the merge request IID from Step 2. The `:id` is automatically resolved by `glab` to the current project.

Filter discussions:
- Keep discussions where at least one note has `resolvable: true` AND `resolved: false`
- Skip discussions where all resolvable notes are `resolved: true`

Map GitLab fields to the display format:
- `position.new_path` → file path
- `position.new_line` → line number
- `note.author.username` → author
- `note.body` → comment body

**Outdated detection**: GitLab does not have an `isOutdated` field like GitHub. If a note's `position` is `null` (the diff context was lost), mark the comment as `(outdated)`. This is a best-effort heuristic.

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

Maintain an internal step list as you work through each comment sequentially.

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
