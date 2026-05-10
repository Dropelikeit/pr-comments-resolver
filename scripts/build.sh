#!/usr/bin/env bash
# Compatible with bash 3.2+ (macOS default ships bash 3.2; no associative arrays).
set -euo pipefail

cd "$(dirname "$0")/.."

ALL_AGENTS=(claude codex augment junie roo)

# Resolve output path for an agent (case statement instead of associative array).
out_path_for() {
  case "$1" in
    claude)  echo "skills/resolve-comments/SKILL.md" ;;
    codex)   echo "dist/codex/skills/resolve-comments/SKILL.md" ;;
    augment) echo "dist/augment/skills/resolve-comments/SKILL.md" ;;
    junie)   echo "dist/junie/.junie/skills/resolve-comments/SKILL.md" ;;
    roo)     echo "dist/roo/.roo/skills/resolve-comments/SKILL.md" ;;
    *) echo "ERROR: unknown agent '$1'" >&2; return 1 ;;
  esac
}

build_one() {
  local agent="$1"
  local adapter_dir="adapters/${agent}"
  local out
  out="$(out_path_for "$agent")"

  test -d "$adapter_dir" || { echo "ERROR: missing adapter dir: $adapter_dir" >&2; return 1; }
  test -f "$adapter_dir/frontmatter.yaml" || { echo "ERROR: missing frontmatter.yaml for $agent" >&2; return 1; }
  test -f "$adapter_dir/prelude.md" || { echo "ERROR: missing prelude.md for $agent" >&2; return 1; }

  mkdir -p "$(dirname "$out")"

  # Concatenate: frontmatter wrapper + prelude + kernel (with placeholder substitution)
  {
    printf -- '---\n'
    cat "$adapter_dir/frontmatter.yaml"
    printf -- '---\n\n'
    cat "$adapter_dir/prelude.md"
    printf '\n'
    python3 scripts/substitute.py core/kernel.md "$adapter_dir/snippets"
  } > "$out"

  echo "Built $agent -> $out"
}

# Args: agent name(s) or 'all'
if [ $# -eq 0 ] || [ "$1" = "all" ]; then
  for agent in "${ALL_AGENTS[@]}"; do
    build_one "$agent"
  done
else
  for agent in "$@"; do
    build_one "$agent"
  done
fi
