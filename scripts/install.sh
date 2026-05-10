#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/install.sh <agent> [--user|--project]

Agents: roo, junie

Examples:
  scripts/install.sh roo --user        # installs to ~/.roo/skills/
  scripts/install.sh junie --project   # installs to ./.junie/skills/
EOF
  exit 1
}

[ $# -ge 1 ] || usage
AGENT="$1"
SCOPE="${2:---project}"

cd "$(dirname "$0")/.."

case "$AGENT" in
  roo)
    SRC="dist/roo/.roo"
    if [ "$SCOPE" = "--user" ]; then DEST="$HOME/.roo"; else DEST="./.roo"; fi
    ;;
  junie)
    SRC="dist/junie/.junie"
    if [ "$SCOPE" = "--user" ]; then DEST="$HOME/.junie"; else DEST="./.junie"; fi
    ;;
  *)
    echo "ERROR: unknown agent '$AGENT'" >&2
    usage
    ;;
esac

test -d "$SRC" || { echo "ERROR: $SRC missing — run 'bash scripts/build.sh $AGENT' first." >&2; exit 1; }

mkdir -p "$DEST"
cp -R "$SRC/." "$DEST/"
echo "Installed $AGENT skill to $DEST"
