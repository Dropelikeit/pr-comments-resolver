## Development Methodology — Spec-Driven Development (SDD)

This project uses Spec-Driven Development. All feature work follows the spec → plan → tasks → execute pipeline.

### Build & Test Commands
- Build (claude only): `bash scripts/build.sh claude`
- Build (all agents): `bash scripts/build.sh all`
- Validate generated artifacts: `python3 scripts/validate.py`
- Smoke test: `bash tests/build_test.sh`
- Lint: none configured
- Platform targets: each adapter under `adapters/` (claude, codex, augment, junie, roo) produces its own SKILL.md plus, after the bitbucket/azure feature lands, a sibling `platforms/<name>.md` per platform.

### Before implementing any feature:
1. Read `specs/[feature]/spec.md` to understand what to build and why
2. Read `specs/[feature]/plan.md` to understand the technical approach
3. Read `specs/[feature]/tasks.md` to find the current task
4. Read `specs/memory/constitution.md` for architectural principles

### While implementing:
- Follow the task list in strict order — don't skip ahead
- Write the test FIRST. Run it to confirm it fails. Then implement until it passes. This is non-negotiable.
- For this Markdown plugin "test" means extending `tests/build_test.sh` assertions and/or `scripts/validate.py` checks, then watching them fail, then writing the source content, then watching them pass.
- Mark tasks `[~]` when starting, `[x]` when done — keep tasks.md in sync at all times
- For `[P]` (parallel) tasks: launch them as concurrent subagents using the Agent tool, one per task
- At `[C]` (checkpoint) tasks: run the full smoke test AND the build for the affected adapter(s), audit task marks, check against spec acceptance criteria, and record results in progress.md before continuing

### Non-goals in the spec are hard boundaries
Do not implement anything listed under "Non-Goals" in a feature's spec.md, even if it seems like a small addition.

### When starting a new session
1. Read `specs/[feature]/progress.md` to understand where the previous session left off
2. Run `bash tests/build_test.sh` to verify the current state matches the last checkpoint
3. Pick up from the first incomplete task in tasks.md

### Project-specific reminders
- Never edit generated files (`skills/resolve-comments/SKILL.md`, anything under `dist/`). Edit the source under `core/` and `adapters/`, then rebuild.
- Secret hygiene: env-var references only, never literal tokens (Constitution §6).
