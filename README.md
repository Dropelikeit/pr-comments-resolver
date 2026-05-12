# PR Comments Resolver

A multi-agent skill plugin that resolves unresolved PR/MR review comments across GitHub, GitLab, Bitbucket Cloud, and Azure DevOps.

Supported agents: **Claude Code**, **Augment**, **Codex**, **Junie**, **Roo Code**.

## Features

- **Multi-platform**: GitHub (Pull Requests), GitLab (Merge Requests), Bitbucket Cloud, and Azure DevOps.
- **Auto-detection**: Identifies the hosting platform from the git remote URL.
- **Pluggable auth**: For Bitbucket and Azure DevOps you choose between a CLI path (analogous to `gh`/`glab`) and an MCP-server path. The skill remembers your choice per repository.
- **Secret hygiene**: PATs are never written to memory or MCP config files — only env-variable references (e.g. `${AZURE_DEVOPS_PAT}`).
- **Memory**: Saves platform settings so subsequent runs skip detection and auth-method selection.
- **Configurable verification**: Runs project-defined lint, test, and analysis commands from `CLAUDE.md` (or `AGENTS.md` as fallback).
- **Language-agnostic**: Works with any programming language or framework.

## Supported Platforms

| Platform | CLI path | MCP path |
|---|---|---|
| GitHub | `gh` | — |
| GitLab | `glab` | — |
| Bitbucket Cloud | `acli` ([Atlassian CLI](https://developer.atlassian.com/cloud/acli/)) | [Atlassian Remote MCP](https://mcp.atlassian.com/v1/sse) (OAuth) |
| Azure DevOps | `az` + the [`azure-devops` extension](https://learn.microsoft.com/azure/devops/cli/) | [`@azure-devops/mcp`](https://www.npmjs.com/package/@azure-devops/mcp) (PAT via env var) |

For platforms with two paths the skill prompts on first use. The choice is persisted in project memory and skipped on subsequent runs.

## Installation

### Claude Code

```txt
/plugin marketplace add Dropelikeit/pr-comments-resolver
/plugin install pr-comments-resolver@pr-comments-resolver
```

### Augment

Augment reads the same `.claude-plugin/` manifests as Claude, plus its own `.augment-plugin/`. Install via Augment's plugin/marketplace UI by pointing it at this repository.

### Codex

Codex auto-discovers `.codex-plugin/` and the repo-scoped marketplace at `.agents/plugins/marketplace.json`. Install via Codex's plugin command using this repository as the source.

### Junie

Junie does not self-publish; install manually:

```sh
bash scripts/install.sh junie --user      # install to ~/.junie/skills/
bash scripts/install.sh junie --project   # install to ./.junie/skills/
```

### Roo Code

Roo Code does not have a public marketplace format; install manually:

```sh
bash scripts/install.sh roo --user        # install to ~/.roo/skills/
bash scripts/install.sh roo --project     # install to ./.roo/skills/
```

## Prerequisites

Depending on your hosting platform and chosen auth method, install one of the following.

### CLI paths

| Platform | CLI Tool | Install | Auth |
|---|---|---|---|
| GitHub | `gh` | [cli.github.com](https://cli.github.com/) | `gh auth login` |
| GitLab | `glab` | [gitlab.com/gitlab-org/cli](https://gitlab.com/gitlab-org/cli) | `glab auth login` |
| Bitbucket Cloud | `acli` | [developer.atlassian.com/cloud/acli](https://developer.atlassian.com/cloud/acli/) | `acli auth login` |
| Azure DevOps | `az` + `azure-devops` extension | [learn.microsoft.com/cli/azure/install-azure-cli](https://learn.microsoft.com/cli/azure/install-azure-cli) | `az extension add --name azure-devops` then `az login` |

The skill verifies authentication before doing any work and stops with a specific install/login instruction if something is missing.

### MCP paths

Bitbucket and Azure DevOps additionally support an MCP-server path. The skill writes the MCP server entry for you (`mcpServers.atlassian` or `mcpServers.ado`) into `~/.claude.json` by default, or `.mcp.json` in the repository if you prefer project scope. If an entry already exists, the skill shows you the diff and asks before overwriting — it never mutates existing configuration silently.

#### Bitbucket Cloud (Atlassian Remote MCP)

Nothing to install or configure ahead of time. The MCP server lives at `https://mcp.atlassian.com/v1/sse` and uses OAuth, so the first MCP tool call opens a browser for you to authenticate. The skill writes the following entry on your behalf:

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

After the write you restart Claude Code; the OAuth handshake happens automatically on first use.

#### Azure DevOps (`@azure-devops/mcp`)

You need a [Personal Access Token (PAT)](https://learn.microsoft.com/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate) for your organisation. **Never paste the PAT into the MCP config** — the skill enforces this for you by writing only an env-variable reference.

1. Add the PAT to your shell profile (e.g. `~/.zshrc`):

   ```sh
   export AZURE_DEVOPS_PAT='<your-personal-access-token>'
   ```

   Reload the shell (`source ~/.zshrc`) so the variable is set in the current environment. The skill verifies the variable is set *before* writing the MCP config and stops with an instruction otherwise — your token value is never read into the skill, only its name.

2. Run `/resolve-comments`. On first run, the skill asks for your Azure DevOps organisation name and the env-variable name (default `AZURE_DEVOPS_PAT`), then writes:

   ```json
   {
     "mcpServers": {
       "ado": {
         "command": "npx",
         "args": ["-y", "@azure-devops/mcp", "<your-org>", "--authentication", "pat"],
         "env": {
           "PERSONAL_ACCESS_TOKEN": "${AZURE_DEVOPS_PAT}"
         }
       }
     }
   }
   ```

3. Restart Claude Code, then re-run `/resolve-comments`. The MCP server resolves the env variable at start-up; the PAT value never lands in any config file or in the project memory.

## Usage

Trigger the skill with the slash command:

```txt
/resolve-comments
```

Or provide a specific PR/MR number:

```txt
/resolve-comments 42
```

The skill will:

1. Detect your hosting platform from the git remote
2. For Bitbucket / Azure DevOps on first use, ask whether you want the CLI or MCP path (remembered for next time)
3. Verify auth (CLI logged in, or MCP tools present); on failure, print the exact install/login command and stop
4. Fetch all unresolved review comments / discussions / threads
5. Work through each comment sequentially
6. Run verification commands (from your project's `CLAUDE.md` or `AGENTS.md`)
7. Self-review all changes
8. Provide a summary

## Verification Commands

The skill looks for verification commands in your project's `CLAUDE.md` (or `AGENTS.md` if Claude is not in use). Define them however fits your project:

- PHP: `task cs-fixer`, `task psalm`, `task test`
- JavaScript: `npm run lint`, `npm test`
- Python: `ruff check .`, `pytest`
- Go: `go vet ./...`, `go test ./...`

If no commands are found, the skill will ask you what to run (or skip verification).

## License

MIT
