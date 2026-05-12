# Pending commits for this feature branch

GPG signing is broken in the current environment; the user commits at the end. Subagents staged work without committing. Each entry below is a logical commit boundary with the proposed message.

## Release workflow — read first

`.github/workflows/release.yml` uses `mathieudutour/github-tag-action@v6.2`. It tags the next version on every push to `main` based on **Conventional Commits** since the last tag.

- **Default bump:** `patch` (would land on `0.2.7`).
- **Minor bump:** any `feat:` commit (would land on `0.3.0`).
- **Major bump (required for 1.0.0):** at least one commit with a `BREAKING CHANGE:` footer **or** a `!` suffix on the type (e.g. `refactor!:`, `feat!:`).

After tagging, the `sync-version` job rewrites the `version` field in **all six** manifest entries:

- `.claude-plugin/plugin.json` (root)
- `.claude-plugin/marketplace.json` (`plugins[name=pr-comments-resolver].version`)
- `.augment-plugin/plugin.json` (root)
- `.augment-plugin/marketplace.json` (root **and** `plugins[].version`)
- `.codex-plugin/plugin.json` (root)

The manifest version fields we set manually below will be overwritten by `sync-version` to whatever the tag action decided. The literal value `"1.0.0"` is in the files mostly for the PR-review experience — the source of truth for the released version is the git tag.

**Therefore:** mark at least one of the commits below as a breaking change so the auto-tagger picks `v1.0.0`. The plan-of-record choice is commit #4 (`feat!: …`) since adding Bitbucket + Azure DevOps with the modular refactor is what justifies the major bump.

`.github/workflows/verify-build.yml` additionally enforces no drift in `skills/` and `dist/`, so the generated artifacts must be in the same commits as their source changes — or in a separate final commit before the PR is opened.

## 1. Phase 1 — build pipeline foundation

**Files staged:**
- `scripts/build.sh`
- `scripts/validate.py`
- `tests/build_test.sh`
- `core/platforms/.gitkeep` (new)

**Proposed message:**
```
build: emit per-platform modules alongside SKILL.md

Foundation for the Bitbucket and Azure DevOps platform support feature.
Adds a build-pipeline loop that substitutes every core/platforms/*.md
through the existing adapter snippets and writes the output into a sibling
platforms/ directory next to each agent's SKILL.md. validate.py and the
smoke test now assert per-platform module presence and integrity.

No platform sources land in this commit — that happens in subsequent phases.
```

## 2. Phase 2 — extract GitHub and GitLab

**Files staged:**
- `core/kernel.md`
- `core/platforms/github.md` (new)
- `core/platforms/gitlab.md` (new)

**Proposed message:**
```
feat(platforms): extract GitHub and GitLab into platform modules

Move all GitHub and GitLab specific commands out of core/kernel.md and
into core/platforms/{github,gitlab}.md. The kernel now loads the
platform module after persistence (Step 1.5) and defers auth, repo
identifier, PR/MR detection, and comment fetching to the module.
Display rendering and resolver flow stay in the kernel.
```

## 3. Phase 3 — memory schema + MCP config writer

**Files staged:**
- `adapters/claude/snippets/persistence-step.md`
- `adapters/augment/snippets/persistence-step.md`
- `adapters/junie/snippets/persistence-step.md`
- `adapters/roo/snippets/persistence-step.md`
- `adapters/claude/snippets/mcp-config-writer.md` (new)
- `adapters/codex/snippets/mcp-config-writer.md` (new, stub)
- `adapters/augment/snippets/mcp-config-writer.md` (new, stub)
- `adapters/junie/snippets/mcp-config-writer.md` (new, stub)
- `adapters/roo/snippets/mcp-config-writer.md` (new, stub)
- `core/kernel.md`

**Proposed message:**
```
feat(schema): extend persistence schema and add MCP Config Writer snippets

- Extend persistence-step snippets (claude/augment/junie/roo) with
  auth-method, mcp-server, token-env-var, and org/workspace fields;
  document back-compat default of `cli` for older memories.
- Add MCP Config Writer snippet for claude with file-selection,
  diff-on-conflict, env-var-only secret handling, and restart notice.
- Add stub MCP Config Writer snippets for codex/augment/junie/roo
  directing users to configure manually.
- Reference `<!-- ADAPTER: mcp-config-writer -->` from core/kernel.md.
- Codex persistence-step intentionally untouched (no persistence layer).
```

## 4. Phase 4 — Bitbucket and Azure platform modules **(breaking-change commit)**

**Files staged:**
- `core/platforms/bitbucket.md` (new)
- `core/platforms/azure.md` (new)
- `core/kernel.md`
- `tests/build_test.sh`

**Proposed message** — note the `!` suffix and the `BREAKING CHANGE:` footer; this is what makes the release workflow tag `v1.0.0` instead of `v0.3.0`:

```
feat(platforms)!: add Bitbucket Cloud and Azure DevOps modules

- Bitbucket Cloud: CLI (acli) + MCP (Atlassian Remote, OAuth)
- Azure DevOps: CLI (az + azure-devops extension) + MCP (@azure-devops/mcp,
  PAT via env-var reference — never the value)
- kernel.md Step 1.2: add bitbucket.org row, drop "CLI Required" column
  (auth method now per-platform), remove "Azure DevOps not supported" stop
- build_test.sh: per-platform content assertions including a negative
  regex rejecting literal-looking PATs in the Azure module

BREAKING CHANGE: The source layout splits core/kernel.md into a thin
orchestrator plus per-platform modules under core/platforms/. The platform
memory schema gains required fields (Auth method, MCP server id, Token
env var, Org / Workspace) for the new platforms; older memories without
Auth method continue to be read as `cli` for back-compat. The build
pipeline now emits a platforms/<name>.md sibling for every SKILL.md per
agent. Anyone consuming `core/` or the generated layout programmatically
should re-test against the new tree.
```

## 5. Phase 5 — centralize auth-method prompt in orchestrator

**Files staged:**
- `core/kernel.md`
- `core/platforms/bitbucket.md`
- `core/platforms/azure.md`

**Proposed message:**
```
refactor(skill): centralize auth-method prompt in orchestrator

Insert kernel Step 1.3 "Select Auth Method (Bitbucket and Azure only)";
shift Verify Auth → 1.4, Persist → 1.5, Load Module → 1.6, Get Repo Id
→ 1.7. Update the Step 1.1 short-circuit to skip to Step 1.6.

Replace the platform-module "Auth method selection" headings in
bitbucket.md and azure.md with a one-line note pointing back to the
orchestrator and a reference list of the two options for readers
landing on the module directly.

Document the back-compat default (`cli` when memory lacks `Auth method`)
in kernel Step 1.1.
```

## 6. Phase 6 — docs and version bump (manifests + CHANGELOG + README)

**Files staged:**
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `.augment-plugin/plugin.json`
- `.augment-plugin/marketplace.json`
- `.codex-plugin/plugin.json`
- `CHANGELOG.md`
- `README.md`

**Proposed message:**
```
chore: release 1.0.0 with Bitbucket and Azure DevOps support

Bump all six manifest version fields to 1.0.0 (Claude, Augment, Codex
across plugin.json and marketplace.json). Update descriptions and
keyword/tag arrays in the Augment and Codex manifests to mention all
four platforms. Document the CLI and MCP paths for Bitbucket and Azure
DevOps in README (Prerequisites tables + MCP setup subsections). Add a
[1.0.0] section to CHANGELOG covering additions, the source-split
refactor, and the back-compat guarantee for existing GH/GL memories.

The version literals here mirror the breaking-change tag the release
workflow will apply on merge to main; the canonical version source
remains the git tag.
```

---

## 7. Adapter descriptions — Bitbucket + Azure DevOps

Found during scenario review: the per-adapter `frontmatter.yaml` description and `prelude.md` opening line still listed only "GitHub or GitLab" for all five adapters. Updated all `adapters/*/frontmatter.yaml` and `adapters/*/prelude.md` to include Bitbucket Cloud and Azure DevOps.

**Files staged:**
- `adapters/claude/frontmatter.yaml`, `adapters/claude/prelude.md`
- `adapters/codex/frontmatter.yaml`, `adapters/codex/prelude.md`
- `adapters/augment/frontmatter.yaml`, `adapters/augment/prelude.md`
- `adapters/junie/frontmatter.yaml`, `adapters/junie/prelude.md`
- `adapters/roo/frontmatter.yaml`, `adapters/roo/prelude.md`

**Proposed message:**
```
docs(adapters): broaden description and prelude to all four platforms

The per-adapter frontmatter description and prelude opening line still
listed only "GitHub or GitLab"; this caused the marketplace-discovery
description and the generated SKILL.md opening line to under-sell the
new platform support. Rewrite to include Bitbucket Cloud and Azure
DevOps in all five adapters.
```

---

## Generated artifacts (not yet decided)

After committing the seven logical commits above, the generated outputs under `skills/resolve-comments/` and `dist/<agent>/` will have drifted (they reflect the new platform modules and updated kernel). The project's CI workflow `.github/workflows/verify-build.yml` asserts no build drift — meaning the generated files MUST be checked in.

Suggested final step: `bash scripts/build.sh all`, then `git add skills/resolve-comments/ dist/` and commit as:

```
chore: rebuild all adapter outputs for 0.3.0
```

