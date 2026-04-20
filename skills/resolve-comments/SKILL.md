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

If no PR/MR exists for the current branch, ask the user for the PR/MR number via AskUserQuestion.

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
