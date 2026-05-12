# Platform Module: GitLab

This module is loaded by the orchestrator when the detected platform is `gitlab`.

## Auth verification

```bash
glab auth status
```

Missing CLI: "Install the GitLab CLI: https://gitlab.com/gitlab-org/cli — then run `glab auth login`". Then stop.
Not authenticated: "Run `glab auth login`". Then stop.

## Repository identifier

```bash
glab repo view --output json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['full_name'])"
```
Format: `<namespace>/<project>`.

## MR IID (if not provided)

```bash
glab mr view --output json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['iid'], d['title'])"
```

## Fetch unresolved discussions

```bash
glab api "projects/:id/merge_requests/MR_IID/discussions"
```

Replace `MR_IID` with the merge request IID. The `:id` is automatically resolved by `glab` to the current project.

Filter:
- Keep discussions where at least one note has `resolvable: true` AND `resolved: false`.
- Skip discussions where all resolvable notes are `resolved: true`.

Field mapping:
- `position.new_path` → file path
- `position.new_line` → line number
- `note.author.username` → author
- `note.body` → comment body

**Outdated:** GitLab has no `isOutdated`. If `position` is `null`, mark `(outdated)`. Best-effort heuristic.

## Post reply and resolve discussion

Use `glab api` POST against the discussion notes endpoint to reply, and PUT against the discussion to set `resolved: true`. Exact endpoints are looked up at execution time against the installed `glab` version.
