# PR Comments Resolver

A Claude Code skill plugin that resolves unresolved PR/MR review comments across GitHub and GitLab.

## Features

- **Multi-platform**: Supports GitHub (Pull Requests) and GitLab (Merge Requests)
- **Auto-detection**: Identifies the hosting platform from the git remote URL
- **CLI verification**: Checks that the required CLI tool (`gh` or `glab`) is installed and authenticated
- **Memory**: Saves platform settings so subsequent runs skip detection
- **Configurable verification**: Runs project-defined lint, test, and analysis commands from CLAUDE.md
- **Language-agnostic**: Works with any programming language or framework

## Installation

### 1. Add a marketplace

First, add my Marketplace to Claude Code:

```txt
/plugin marketplace add Dropelikeit/pr-comments-resolver
```

### 2. Install plugin

```txt
/plugin install pr-comments-resolver@pr-comments-resolver
```

## Prerequisites

Depending on your hosting platform, you need one of these CLI tools installed and authenticated:

| Platform | CLI Tool | Install                                                        | Auth              |
|----------|----------|----------------------------------------------------------------|-------------------|
| GitHub   | `gh`     | [cli.github.com](https://cli.github.com/)                      | `gh auth login`   |
| GitLab   | `glab`   | [gitlab.com/gitlab-org/cli](https://gitlab.com/gitlab-org/cli) | `glab auth login` |

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

1. Detect your hosting platform and verify CLI access
2. Fetch all unresolved review comments
3. Work through each comment sequentially
4. Run verification commands (from your project's CLAUDE.md)
5. Self-review all changes
6. Provide a summary

## Verification Commands

The skill looks for verification commands in your project's `CLAUDE.md`. Define them however fits your project:

- PHP: `task cs-fixer`, `task psalm`, `task test`
- JavaScript: `npm run lint`, `npm test`
- Python: `ruff check .`, `pytest`
- Go: `go vet ./...`, `go test ./...`

If no commands are found, the skill will ask you what to run (or skip verification).

## Supported Platforms

| Platform     | Status       |
|--------------|--------------|
| GitHub       | Supported    |
| GitLab       | Supported    |
| Azure DevOps | Planned (v2) |

## License

MIT
