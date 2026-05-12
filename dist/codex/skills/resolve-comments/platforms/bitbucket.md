# Platform Module: Bitbucket Cloud

This module is loaded by the orchestrator when the detected platform is `bitbucket` (remote URL contains `bitbucket.org`).

## Auth method

Routed by the orchestrator (kernel Step 1.3). Follow **Path A (CLI)** or **Path B (MCP)** below according to the `Auth method` value recorded in memory for this repository.

For reference, the two options the orchestrator presents are:

- `CLI (acli)` — Atlassian's command-line tool, uses local auth tokens managed by `acli auth login`.
- `MCP (Atlassian Remote)` — official OAuth-based MCP server at `https://mcp.atlassian.com/v1/sse`. No PAT required; OAuth happens in the browser on first MCP tool call.

## Path A — CLI (acli)

### Auth verification

```bash
acli auth status
```

- Missing CLI: "Install acli from https://developer.atlassian.com/cloud/acli/ and run `acli auth login`". Then stop.
- Not authenticated: "Run `acli auth login`". Then stop.

### Repository identifier

Parse the remote URL `https://bitbucket.org/<workspace>/<repo>` into `<workspace>/<repo>`.

### PR number (if not provided)

Use `acli` to list open PRs scoped to the current branch:

```bash
acli bitbucket pr list --repository <workspace>/<repo>
```

(Exact subcommand surface depends on the installed `acli` version — verify against `acli bitbucket pr --help` at execution time.) Match the result against the current branch; if there are zero or multiple matches, ask the user. Ask the user directly in chat with the listed options.

### Fetch unresolved comments

```bash
acli bitbucket pr comments --repository <workspace>/<repo> --id <pr>
```

(Exact subcommand verified at execution time.) Map the response to the uniform `{id, file, line, author, body, thread_id, resolved}` shape. Filter to `resolved: false`.

### Post reply / resolve thread

Use the `acli` PR comment reply and resolve subcommands. Exact command names are verified at execution time against the installed version.

## Path B — MCP (Atlassian Remote)

### Auth verification

Check whether Atlassian MCP tools (e.g. tools whose names begin with `atlassian_` or contain `bitbucket_pr_`) are present in the current tool inventory. If yes → proceed to the operations below. If no → run the setup step.

### Setup

Invoke the MCP Config Writer (see Step 1.5 of the orchestrator) with this entry:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/sse"]
    }
  }
}
```

No PAT prompt — OAuth is used. The user authenticates in the browser on first MCP tool call. After the Config Writer writes the entry, persist memory with `Auth method: mcp`, `MCP server id: atlassian`, no `Token env var`. Tell the user to restart Claude Code and complete the OAuth flow on first invocation. Stop the skill.

### Repository identifier, comment fetch, replies, resolves

Use the Atlassian MCP tools for Bitbucket PR threads. Exact tool names are verified against the live MCP inventory at execution time, then mapped to the uniform comment shape.
