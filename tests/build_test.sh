#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Smoke test: build script produces non-empty Claude SKILL.md with required structure
bash scripts/build.sh claude

OUT="skills/resolve-comments/SKILL.md"
test -s "$OUT" || { echo "FAIL: $OUT empty or missing"; exit 1; }
head -1 "$OUT" | grep -q '^---$' || { echo "FAIL: $OUT missing frontmatter"; exit 1; }
grep -q '^name: resolve-comments$' "$OUT" || { echo "FAIL: missing name"; exit 1; }
grep -q '^trigger: /resolve-comments$' "$OUT" || { echo "FAIL: missing trigger"; exit 1; }
grep -q 'TodoWrite' "$OUT" || { echo "FAIL: track-tasks snippet not substituted"; exit 1; }
grep -q 'CLAUDE.md' "$OUT" || { echo "FAIL: context-file-name snippet not substituted"; exit 1; }
! grep -q '<!-- ADAPTER: ' "$OUT" || { echo "FAIL: unsubstituted placeholders remain"; exit 1; }

for needle in "Step 3.5" "Step 4b" "Reply/Resolve permission" "Classification"; do
  grep -qF "$needle" skills/resolve-comments/SKILL.md \
    || { echo "FAIL: missing '$needle' in built Claude SKILL.md"; exit 1; }
done

for d in skills/resolve-comments dist/*/skills/resolve-comments; do
  [ -f "$d/SKILL.md" ] || continue
  for needle in "skill-availability" "classify-confirm"; do
    if grep -q "<!-- ADAPTER: $needle -->" "$d/SKILL.md"; then
      echo "FAIL: unsubstituted ADAPTER placeholder '$needle' in $d/SKILL.md"; exit 1
    fi
  done
done

# Platform modules must be built into a sibling platforms/ directory
PLATFORMS_DIR="skills/resolve-comments/platforms"
for p in github gitlab bitbucket azure; do
  f="$PLATFORMS_DIR/$p.md"
  test -s "$f" || { echo "FAIL: $f empty or missing"; exit 1; }
  ! grep -q '<!-- ADAPTER: ' "$f" || { echo "FAIL: unsubstituted placeholders in $f"; exit 1; }
done

# Per-platform content assertions
BB="skills/resolve-comments/platforms/bitbucket.md"
grep -q 'acli' "$BB" || { echo "FAIL: $BB missing acli reference"; exit 1; }
grep -q 'mcp.atlassian.com/v1/sse' "$BB" || { echo "FAIL: $BB missing Atlassian Remote MCP URL"; exit 1; }

AZ="skills/resolve-comments/platforms/azure.md"
grep -q 'az repos pr' "$AZ" || { echo "FAIL: $AZ missing az CLI reference"; exit 1; }
grep -q '@azure-devops/mcp' "$AZ" || { echo "FAIL: $AZ missing Azure DevOps MCP reference"; exit 1; }
grep -q 'AZURE_DEVOPS_PAT' "$AZ" || { echo "FAIL: $AZ missing default env-var name"; exit 1; }
! grep -E 'PERSONAL_ACCESS_TOKEN[^$]*[A-Za-z0-9]{20,}' "$AZ" || { echo "FAIL: $AZ contains literal-looking PAT"; exit 1; }

echo "PASS"
