---
name: resolve-comments
description: Use when resolving unresolved PR or MR review comments, working through reviewer feedback, or addressing code review threads on GitHub or GitLab repositories
trigger: /resolve-comments
---

# Resolve PR/MR Review Comments

Work through all unresolved review comments from a pull request (GitHub) or merge request (GitLab).

## Step 1: Platform Detection & CLI Verification

### 1.1 Check Memory

Check Claude's project memory for a previously saved `pr-comments-resolver-platform` configuration. If found, run a quick CLI auth verification:

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

If the URL does not match any known pattern (e.g., a self-hosted instance), ask the user which platform this repository is hosted on via AskUserQuestion with options: GitHub, GitLab, Other.

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

### 1.4 Save to Memory

After successful detection and CLI verification, save a project memory:

```markdown
---
name: pr-comments-resolver-platform
description: Detected hosting platform and CLI tool for this repository
type: project
---

Platform: <github|gitlab>
CLI tool: <gh|glab>
Repository: <owner/repo or namespace/project>
```

### 1.5 Get Repository Identifier

- **GitHub**:
```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

- **GitLab**:
```bash
glab repo view --output json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['full_name'])"
```
