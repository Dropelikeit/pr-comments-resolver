# Development Constitution

These principles guide all technical decisions in this project. They're defaults, not dogma — the team can override any principle for a specific feature by documenting the rationale in that feature's plan.md. But when no strong reason exists to deviate, follow these.

## Principles

### 1. Test-First
Write tests before implementation code. Tests serve two purposes: they verify correctness, and they force you to think about the interface before the internals. If you can't write a test for something, you probably don't understand it well enough to build it.

For this Markdown-skill plugin specifically: the test surface is `scripts/validate.py` (frontmatter + snippet-coverage) and `tests/build_test.sh` (built-file smoke assertions). Extend these assertions before adding source content, then run them to confirm failure, then add the content, then re-run.

### 2. Simplicity
Choose the simplest approach that satisfies the requirements. Complexity is a cost — it slows down future changes, increases the surface area for bugs, and makes onboarding harder. If two solutions both work, prefer the one that's easier to understand.

### 3. Explicit Over Implicit
Make behavior visible and predictable. Prefer explicit configuration over convention, clear error messages over silent failures, and named functions over clever one-liners. Code is read far more often than it's written.

### 4. Integration-First Testing
Prioritize integration tests that exercise real workflows over unit tests that test isolated functions. Unit tests are fine for complex logic, but integration tests catch the bugs that actually affect users — the ones that live in the seams between components.

For skill content: the "integration test" is a manual scenario walkthrough where a competent engineer follows the generated SKILL.md and platform modules through a realistic decision tree.

### 5. No Premature Abstraction
Don't abstract until you've seen the pattern repeat. Write concrete code first. When you see the same pattern three times, then consider extracting it. Abstractions created too early often don't match the actual shape of the problem, and you end up fighting them.

### 6. Secret Hygiene (project-specific)
Never write a secret value (PAT, password, API token) to disk. Memory files, MCP config files, generated artifacts, and committed source must store only `${ENV_VAR_NAME}` references and the name of the env variable — never the value.
