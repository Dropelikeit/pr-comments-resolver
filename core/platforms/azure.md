# Platform Module: Azure DevOps

This module is loaded by the orchestrator when the detected platform is `azure` (remote URL contains `dev.azure.com` or `visualstudio.com`).

## Auth method

Routed by the orchestrator (kernel Step 1.3). Follow **Path A (CLI)** or **Path B (MCP)** below according to the `Auth method` value recorded in memory for this repository.

For reference, the two options the orchestrator presents are:

- `CLI (az + azure-devops extension)` — uses `az login` (or `az devops login` with a PAT).
- `MCP (@azure-devops/mcp)` — PAT-based MCP server via `npx`, configured with an env-variable reference (no secret on disk).

## Path A — CLI (az)

### Auth verification

```bash
az --version
az extension show --name azure-devops
az account show
```

Any failure → instruct:

- Install the Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli
- `az extension add --name azure-devops`
- `az login` (or `az devops login` if you prefer PAT-based auth — this is informational only, the skill does not automate it)

Then stop.

### Repository identifier

Parse `https://dev.azure.com/<org>/<project>/_git/<repo>` into `<org>/<project>/<repo>`. Variations like `https://<org>.visualstudio.com/<project>/_git/<repo>` should also be handled — extract `<org>`, `<project>`, `<repo>` consistently.

### PR number (if not provided)

```bash
az repos pr list --repository <repo> --output json
```

Match against the current branch. If there is exactly one match, use it. Otherwise ask the user. <!-- ADAPTER: ask-user -->

### Fetch unresolved threads

```bash
az repos pr show --id <pr> --output json
```

For each thread, fetch comments via the Azure DevOps REST API through `az rest` (the `az repos pr` surface for threads is limited):

```bash
az rest --method get --url "https://dev.azure.com/<org>/<project>/_apis/git/repositories/<repo>/pullRequests/<pr>/threads?api-version=7.1"
```

Filter on threads whose `status` is not `closed`, `fixed`, `wontFix`, or `byDesign`. Map to the uniform comment shape.

### Post reply / resolve thread

Use `az rest` against:

- `POST .../pullRequests/<pr>/threads/<thread>/comments` to reply.
- `PATCH .../pullRequests/<pr>/threads/<thread>` with body `{"status": "fixed"}` to resolve.

Exact request bodies are verified at execution time against the installed Azure DevOps REST API version.

## Path B — MCP (@azure-devops/mcp)

### Prompts (in order)

1. Ask: "Azure DevOps organisation name?" (free-text, required). <!-- ADAPTER: ask-user -->
2. Ask: "Name of the env variable holding your PAT?" — offer `AZURE_DEVOPS_PAT` as the default and let the user pick another name. <!-- ADAPTER: ask-user -->

### Env-var presence check

Read the chosen env variable from the current process environment. If unset, tell the user how to set it in their shell profile, for example:

```bash
echo 'export AZURE_DEVOPS_PAT=...' >> ~/.zshrc
source ~/.zshrc
```

Then stop the skill and instruct them to re-run after the variable is in place. Do not write the MCP config until the env variable is set.

### Setup

Invoke the MCP Config Writer (see Step 1.5 of the orchestrator) with this entry, substituting `<orgname>` and `<ENV_VAR_NAME>`:

```json
{
  "mcpServers": {
    "ado": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp", "<orgname>", "--authentication", "pat"],
      "env": {
        "PERSONAL_ACCESS_TOKEN": "${<ENV_VAR_NAME>}"
      }
    }
  }
}
```

Persist memory: `Auth method: mcp`, `MCP server id: ado`, `Org / Workspace: <orgname>`, `Token env var: $<ENV_VAR_NAME>`. **Never persist the token value.**

After the writer completes, tell the user to restart Claude Code, then stop the skill.

### Repository identifier, comment fetch, replies, resolves

Use the `ado` MCP tools (names like `pull_request_get_comments`, `pull_request_create_comment`, `pull_request_resolve_thread` — verified at execution time against the live MCP inventory). Map results to the uniform comment shape.
