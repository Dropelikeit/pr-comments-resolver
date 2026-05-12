# Bitbucket and Azure DevOps Platform Support — Tasks

> Derived from `docs/superpowers/plans/2026-05-12-bitbucket-azure-platforms.md`. That file contains the **full step-by-step code, test snippets, file paths, and commit commands**. This tasks.md is the SDD progress tracker; the plan is the runbook. Subagents executing a task must read the corresponding section of the plan first.

## Status Legend
- `[ ]` Not started
- `[x]` Complete
- `[~]` In progress
- `[P]` Parallelizable — executed concurrently via subagents
- `[C]` Checkpoint — stop and verify before continuing

---

## Phase 1: Foundation — Build pipeline emits per-platform files
*Plan section: Task 1*

- [ ] **1.1 Test:** Extend `tests/build_test.sh` to assert that for every platform name (`github`, `gitlab`, `bitbucket`, `azure`) a non-empty `skills/resolve-comments/platforms/<name>.md` exists with no `<!-- ADAPTER: -->` placeholders. Extend `scripts/validate.py` analogously for every entry in `OUT_PATHS`.
- [ ] **1.2 Test failure:** Run `bash tests/build_test.sh`. Expected: FAIL with "platforms/github.md empty or missing". This proves the assertion is wired up before any source change.
- [ ] **1.3 Implement:** Add `build_platforms()` helper in `scripts/build.sh` that substitutes every `core/platforms/*.md` against the adapter snippets dir and writes to `<output-skill-dir>/platforms/<name>.md`. Call it inside `build_one()`. Create `core/platforms/.gitkeep` so the directory is committed.
- [ ] **1.4 Run:** `bash scripts/build.sh claude && bash tests/build_test.sh`. Expected: still FAIL (loop runs but no platform sources exist yet — confirms the loop is wired up, not skipping silently).
- [ ] **1.5 Commit:** "build: emit per-platform modules alongside SKILL.md"
- [C] **Checkpoint 1:** `bash scripts/build.sh all && python3 scripts/validate.py` must run without crashing. Validate runs but `validate_platform_files()` reports missing entries — that is the expected, recorded state at this checkpoint. Log in `progress.md`.

## Phase 2: Existing-platform extraction
*Plan sections: Task 2 (GitHub), Task 3 (GitLab). Sequential — both edit `core/kernel.md`.*

- [ ] **2.1 Test:** the existing `build_test.sh` GitHub assertion (already in place from Phase 1) should now flip from FAIL to PASS for `github.md` after this task.
- [ ] **2.2 Implement GitHub:** Create `core/platforms/github.md` with the GitHub content extracted verbatim from the plan's Task 2 step 2.1 block. Strip GitHub-specific lines (Step 1.1 GH branch, Step 1.3 GH branch, Step 1.5 GH command, Step 2 GH command, Step 3 GitHub GraphQL block) from `core/kernel.md`. Add the Step 1.5 "Load Platform Module" dispatch instruction.
- [ ] **2.3 Run:** `bash scripts/build.sh claude && bash tests/build_test.sh`. Expected: `platforms/github.md` assertion passes, `platforms/gitlab.md` and others still FAIL.
- [ ] **2.4 Commit:** "refactor(skill): extract GitHub path into platform module"
- [ ] **2.5 Implement GitLab:** Create `core/platforms/gitlab.md` per the plan's Task 3 step 3.1 block. Strip the GitLab-specific lines from `core/kernel.md`.
- [ ] **2.6 Run:** `bash scripts/build.sh claude && bash tests/build_test.sh`. Expected: `platforms/github.md` and `platforms/gitlab.md` assertions both pass; bitbucket and azure still FAIL.
- [ ] **2.7 Commit:** "refactor(skill): extract GitLab path into platform module"
- [C] **Checkpoint 2:** Full build (`bash scripts/build.sh all`) and validate. Record state in `progress.md`. Confirm that no existing GitHub/GitLab behaviour is lost — re-read kernel + github.md + gitlab.md and confirm every instruction from the original kernel is reachable somewhere.

## Phase 3: Schema & shared infrastructure
*Plan sections: Task 4 (memory schema), Task 5 (MCP config writer).*

- [ ] **3.1 Implement memory-schema extension:** For each of the 5 adapters (claude, codex, augment, junie, roo), update `adapters/<agent>/snippets/persistence-step.md` to include the new fields (`Auth method`, `MCP server id`, `Token env var`, `Org / Workspace`) and the back-compat note (missing `Auth method` → `cli`). See plan Task 4 step 4.2 for the exact block.
- [ ] **3.2 Run:** `bash scripts/build.sh all && python3 scripts/validate.py && bash tests/build_test.sh`. Expected: still passes for github/gitlab; bitbucket/azure still expected-FAIL.
- [ ] **3.3 Commit:** "feat(skill): extend platform memory schema with auth method and org fields"
- [ ] **3.4 Implement MCP Config Writer snippet:** Create `adapters/claude/snippets/mcp-config-writer.md` with the full procedure (target file selection, read/diff/prompt/write, secret handling, restart notice). For each non-claude adapter, create `adapters/<agent>/snippets/mcp-config-writer.md` with the equivalent content (full procedure if the adapter's host supports json MCP config; stub if not). See plan Task 5 steps 5.1–5.3 for content.
- [ ] **3.5 Wire kernel reference:** In `core/kernel.md`, in the new "Step 1.5 Load Platform Module" section, append a reference to `<!-- ADAPTER: mcp-config-writer -->`.
- [ ] **3.6 Run:** `bash scripts/build.sh all && python3 scripts/validate.py && bash tests/build_test.sh`. Expected: existing assertions still pass.
- [ ] **3.7 Commit:** "feat(skill): add reusable MCP config writer snippet"
- [C] **Checkpoint 3:** Sanity-grep the generated `skills/resolve-comments/SKILL.md` for `MCP Config Writer` heading and the new schema fields. Record in `progress.md`.

## Phase 4: New platform modules
*Plan sections: Task 6 (Bitbucket), Task 7 (Azure). Sequential, because both extend `tests/build_test.sh`.*

- [ ] **4.1 Test:** Extend `tests/build_test.sh` to assert that `platforms/bitbucket.md` contains both `acli` and `mcp.atlassian.com/v1/sse`. See plan Task 6 step 6.1.
- [ ] **4.2 Test failure:** Run `bash tests/build_test.sh`. Expected: FAIL with "bitbucket.md empty or missing".
- [ ] **4.3 Implement Bitbucket module:** Create `core/platforms/bitbucket.md` per the plan's Task 6 step 6.2 block (CLI Path A + MCP Path B). Update `core/kernel.md`'s Step 1.2 detection table to include the `bitbucket.org` row and remove the "Azure DevOps support is planned" stop.
- [ ] **4.4 Run:** `bash scripts/build.sh all && python3 scripts/validate.py && bash tests/build_test.sh`. Expected: bitbucket assertions pass.
- [ ] **4.5 Commit:** "feat(skill): add Bitbucket Cloud platform module (acli + Atlassian MCP)"
- [ ] **4.6 Test:** Extend `tests/build_test.sh` with the Azure assertions: `platforms/azure.md` must contain `az repos pr`, `@azure-devops/mcp`, `AZURE_DEVOPS_PAT`; and must NOT contain a literal-looking PAT (negative regex `! grep -E 'PERSONAL_ACCESS_TOKEN.*[A-Za-z0-9]{20,}'`).
- [ ] **4.7 Test failure:** Run the smoke test. Expected: FAIL with "azure.md empty or missing".
- [ ] **4.8 Implement Azure module:** Create `core/platforms/azure.md` per the plan's Task 7 step 7.2 (CLI Path A + MCP Path B with org prompt, env-var prompt, env-var presence check, `${ENV_VAR_NAME}` reference).
- [ ] **4.9 Run:** `bash scripts/build.sh all && python3 scripts/validate.py && bash tests/build_test.sh`. Expected: all four platform assertions pass; the negative PAT-regex check passes.
- [ ] **4.10 Commit:** "feat(skill): add Azure DevOps platform module (az CLI + @azure-devops/mcp)"
- [C] **Checkpoint 4:** Cross-check spec acceptance criteria. After this checkpoint the following criteria should be met: detection for bitbucket/azure, secret hygiene (env-var only), platform-module presence, build assertions. Record in `progress.md`.

## Phase 5: Orchestrator wiring
*Plan section: Task 8. Centralises the auth-method prompt in the kernel.*

- [ ] **5.1 Implement:** Add the "1.3 Auth Method Selection" block in `core/kernel.md` after platform detection and before module load. Renumber subsequent subsections (1.3 Verify CLI → 1.4, 1.4 Persist → 1.5, 1.5 Load Module → 1.6). See plan Task 8 step 8.1.
- [ ] **5.2 Trim modules:** In `core/platforms/bitbucket.md` and `core/platforms/azure.md`, replace each "Auth method selection" subsection with a one-line note that routing is owned by the orchestrator.
- [ ] **5.3 Run:** Full build + validate + smoke. All assertions still pass.
- [ ] **5.4 Commit:** "refactor(skill): centralize auth-method prompt in orchestrator"
- [C] **Checkpoint 5:** Verify by reading the generated `skills/resolve-comments/SKILL.md` that the auth-method prompt now lives in the orchestrator only, and that the modules' new one-liner says "Routed by the orchestrator". Record in `progress.md`.

## Phase 6: Docs & version bump
*Plan section: Task 9.*

- [ ] **6.1 Implement:** Bump `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` to `0.3.0`. Add the new platforms section to `README.md`. Add the `## [0.3.0]` block to `CHANGELOG.md` (Added / Changed / Compatibility) per plan Task 9 step 9.4.
- [ ] **6.2 Run:** `bash scripts/build.sh all && python3 scripts/validate.py && bash tests/build_test.sh`. Expected: PASS.
- [ ] **6.3 Commit:** "chore: release 0.3.0 with Bitbucket and Azure DevOps support"

## Build Verification
*Plan section: Task 10. Every command from `.claude/CLAUDE.md`.*

- [ ] **B.1** `bash scripts/build.sh all` — exits 0; produces SKILL.md and platforms/ under both `skills/resolve-comments/` and every `dist/<agent>/.../`.
- [ ] **B.2** `python3 scripts/validate.py` — zero errors.
- [ ] **B.3** `bash tests/build_test.sh` — prints `PASS`.
- [ ] **B.4** Inspect: `ls skills/resolve-comments/platforms/ dist/codex/skills/resolve-comments/platforms/ dist/augment/skills/resolve-comments/platforms/ dist/junie/.junie/skills/resolve-comments/platforms/ dist/roo/.roo/skills/resolve-comments/platforms/` — each must list four files: `github.md`, `gitlab.md`, `bitbucket.md`, `azure.md`.
- [ ] **B.5** Commit any drift in generated outputs (if `git status` shows changes): "chore: rebuild all adapter outputs".

## Scenario Walkthroughs
*Plan section: Task 11. These exercise the prose decision tree where automated tests can't reach. Walk the generated `skills/resolve-comments/SKILL.md` + relevant module under the stated initial state and confirm the documented stop point or branch is reached.*

- [ ] **S.1** GitHub happy path (`github.com` remote, `gh` installed, memory present) → dispatch to `platforms/github.md`, no auth prompt.
- [ ] **S.2** GitLab cold start (`gitlab.com` remote, no memory, `glab` unauthenticated) → detection → instruction to `glab auth login` → stop.
- [ ] **S.3** Bitbucket CLI choice → auth-method prompt → user picks CLI → dispatch to bitbucket.md Path A → `acli auth status`.
- [ ] **S.4** Bitbucket MCP cold start (no Atlassian MCP tools present) → auth-method prompt → user picks MCP → MCP Config Writer scope question → entry written → restart notice → stop.
- [ ] **S.5** Azure CLI happy path → detection → prompt → CLI → repo identifier `org/project/repo` → comment fetch.
- [ ] **S.6** Azure MCP with missing env var (`AZURE_DEVOPS_PAT` unset) → prompts (org, env-var name) → env-var presence check fails → user instructed → stop without writing config.
- [ ] **S.7** Azure MCP with existing differing `ado` entry in `~/.claude.json` → writer presents diff → AskUserQuestion Overwrite/Keep/Abort.
- [ ] **S.8** Back-compat scenario: existing GH/GL memory without `Auth method` → orchestrator reads it as `cli`, proceeds without prompt. (Re-verifies the Phase 3 snippet change.)
- [ ] **S.9** Self-hosted / unknown remote → orchestrator offers GitHub / GitLab / Bitbucket / Azure / Other → Other → "not supported" stop.

For any scenario that surfaces a defect, return to the source (kernel, module, or snippet), fix, rebuild, re-walk. Treat each unfixed defect as a blocker for the next checkpoint.

- [C] **Final Checkpoint:** Re-read `spec.md` acceptance criteria. Every checkbox in the spec must map to a verified scenario or a passing build assertion. If a criterion lacks coverage, add it here or open a follow-up. Record final state in `progress.md`.
