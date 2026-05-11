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

echo "PASS"
