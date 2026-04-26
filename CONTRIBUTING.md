# Contributing to PR Comments Resolver

Thank you for your interest in contributing! This document explains how to get started.

## Ways to Contribute

- **Bug reports** — open an issue describing what happened and what you expected
- **Feature requests** — open an issue with the label `enhancement`
- **Pull requests** — fixes, improvements, or new platform support

## Development Setup

This plugin has no build step. The skill logic lives entirely in `skills/resolve-comments/SKILL.md`.

1. Fork the repository and clone your fork
2. Install [Claude Code](https://claude.ai/code)
3. Install the plugin from your local fork:
   ```
   /plugin install /path/to/your/fork
   ```
4. Open a repository with open PR/MR review comments and run `/resolve-comments` to test

## Project Structure

```
.claude-plugin/          Plugin manifests (plugin.json, marketplace.json)
skills/resolve-comments/ The resolve-comments skill (SKILL.md)
README.md                User-facing documentation
CONTRIBUTING.md          This file
CHANGELOG.md             Version history
PRIVACY.md               Data handling and privacy details
LICENSE                  MIT license
```

## Making Changes

### Editing the Skill

All skill behavior is defined in [`skills/resolve-comments/SKILL.md`](skills/resolve-comments/SKILL.md). The file uses numbered steps with platform-specific branches (GitHub / GitLab).

- Keep steps numbered and self-contained
- Add platform branches (`**GitHub**` / `**GitLab**`) when behavior differs
- Test on both platforms before submitting

### Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md` with the required YAML frontmatter:
   ```yaml
   ---
   name: skill-name
   description: "Use when ..."
   trigger: /skill-name
   ---
   ```
2. Follow the existing step structure
3. Update `README.md` to document the new skill

### Editing Manifests

- `plugin.json` — plugin identity and metadata
- `marketplace.json` — marketplace listing; bump `version` on every release

## Commit Style

This project uses [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add Azure DevOps support
fix: handle missing glab binary gracefully
docs: update installation instructions
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`

## Pull Request Guidelines

- One concern per PR
- Reference the related issue if one exists (`Closes #42`)
- Update `CHANGELOG.md` under `[Unreleased]` with a brief description of your change
- Keep the PR description concise — what changed and why

## Releasing

Releases are created via the GitHub Actions workflow in `.github/workflows/release.yml`. Maintainers trigger it by pushing a version tag:

```bash
git tag v0.2.0
git push origin v0.2.0
```

The workflow publishes a GitHub Release automatically.

## Code of Conduct

Be respectful and constructive. Issues and PRs that are hostile or off-topic will be closed.

## License

By contributing you agree that your changes will be licensed under the [MIT License](LICENSE).
