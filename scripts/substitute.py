#!/usr/bin/env python3
"""Substitute <!-- ADAPTER: <key> --> placeholders in kernel.md with snippet contents."""
import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <kernel-file> <snippets-dir>", file=sys.stderr)
        return 2

    kernel_path = Path(sys.argv[1])
    snippets_dir = Path(sys.argv[2])

    text = kernel_path.read_text()
    pattern = re.compile(r'<!-- ADAPTER: ([a-z0-9-]+) -->')

    def replace(match):
        key = match.group(1)
        snippet_path = snippets_dir / f"{key}.md"
        if not snippet_path.exists():
            # Missing snippet -> empty replacement (allows agent to omit a step).
            return ""
        return snippet_path.read_text().rstrip("\n")

    sys.stdout.write(pattern.sub(replace, text))
    return 0


if __name__ == "__main__":
    sys.exit(main())
