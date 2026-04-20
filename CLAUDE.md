# PR Comments Resolver — Development Guide

## Project Structure

This is a Claude Code skill plugin. The main skill file is `skills/resolve-comments/SKILL.md`.

```
.claude-plugin/          Plugin manifests (plugin.json, marketplace.json)
skills/resolve-comments/ The resolve-comments skill
README.md                User-facing documentation
CLAUDE.md                This file
LICENSE                  MIT license
```

## Plugin Format

All skill content lives in `skills/<skill-name>/SKILL.md`. Each SKILL.md requires YAML frontmatter with `name`, `description`, and optionally `trigger`.

The `.claude-plugin/plugin.json` defines the plugin identity. The `.claude-plugin/marketplace.json` contains metadata for marketplace distribution.

## Conventions

- All `.md` files are written in English
- SKILL.md frontmatter `description` must start with "Use when..." and describe triggering conditions only (max 500 chars)
- Skill names use kebab-case
- This is a multi-skill plugin — future skills go in `skills/<new-skill-name>/SKILL.md`

## Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md` with the required frontmatter
2. Follow the existing skill structure (numbered steps, platform-specific branches)
3. Update `README.md` to document the new skill
