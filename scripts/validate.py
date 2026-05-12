#!/usr/bin/env python3
"""Validate generated SKILL.md frontmatter and verify snippet coverage."""
import re
import sys
from pathlib import Path

REQUIRED_KEYS = {"name", "description"}
DESCRIPTION_PREFIX = "Use when"
DESCRIPTION_MAX = 500

ROOT = Path(__file__).resolve().parent.parent
ADAPTERS_DIR = ROOT / "adapters"
KERNEL_PATH = ROOT / "core" / "kernel.md"

# Output paths per agent — must match scripts/build.sh
OUT_PATHS = {
    "claude":  ROOT / "skills/resolve-comments/SKILL.md",
    "codex":   ROOT / "dist/codex/skills/resolve-comments/SKILL.md",
    "augment": ROOT / "dist/augment/skills/resolve-comments/SKILL.md",
    "junie":   ROOT / "dist/junie/.junie/skills/resolve-comments/SKILL.md",
    "roo":     ROOT / "dist/roo/.roo/skills/resolve-comments/SKILL.md",
}

PLATFORM_NAMES = ["github", "gitlab", "bitbucket", "azure"]

errors = []


def parse_frontmatter(path):
    text = path.read_text()
    match = re.match(r'^---\n(.*?)\n---\n', text, re.DOTALL)
    if not match:
        errors.append(f"{path}: missing or malformed frontmatter")
        return {}
    fm = {}
    for line in match.group(1).splitlines():
        if ":" in line:
            k, _, v = line.partition(":")
            fm[k.strip()] = v.strip()
    return fm


def validate_frontmatter(agent, path):
    if not path.exists():
        errors.append(f"{agent}: output missing at {path}")
        return
    fm = parse_frontmatter(path)
    if not fm:
        return
    missing = REQUIRED_KEYS - fm.keys()
    if missing:
        errors.append(f"{agent}: frontmatter missing keys: {sorted(missing)}")
    desc = fm.get("description", "")
    if not desc.startswith(DESCRIPTION_PREFIX):
        errors.append(f"{agent}: description must start with '{DESCRIPTION_PREFIX}' (got: {desc[:60]!r})")
    if len(desc) > DESCRIPTION_MAX:
        errors.append(f"{agent}: description is {len(desc)} chars (max {DESCRIPTION_MAX})")


def validate_snippet_coverage():
    if not KERNEL_PATH.exists():
        errors.append(f"kernel missing at {KERNEL_PATH}")
        return
    keys = set(re.findall(r'<!-- ADAPTER: ([a-z0-9-]+) -->', KERNEL_PATH.read_text()))
    if not ADAPTERS_DIR.exists():
        return
    for adapter in sorted(ADAPTERS_DIR.iterdir()):
        if not adapter.is_dir():
            continue
        snippets_dir = adapter / "snippets"
        present = {p.stem for p in snippets_dir.glob("*.md")} if snippets_dir.exists() else set()
        missing = keys - present
        if missing:
            print(f"NOTE: {adapter.name} has no snippet for: {sorted(missing)} (will substitute empty)", file=sys.stderr)


def validate_no_stray_placeholders():
    for agent, path in OUT_PATHS.items():
        if not path.exists():
            continue
        if "<!-- ADAPTER: " in path.read_text():
            errors.append(f"{agent}: output contains unsubstituted placeholders")


def validate_platform_files():
    for agent, skill_path in OUT_PATHS.items():
        platforms_dir = skill_path.parent / "platforms"
        for name in PLATFORM_NAMES:
            p = platforms_dir / f"{name}.md"
            if not p.exists():
                errors.append(f"{p}: missing platform module")
                continue
            text = p.read_text()
            if "<!-- ADAPTER: " in text:
                errors.append(f"{p}: unsubstituted ADAPTER placeholder")
            if not text.strip():
                errors.append(f"{p}: empty file")


def main():
    for agent, path in OUT_PATHS.items():
        validate_frontmatter(agent, path)
    validate_snippet_coverage()
    validate_no_stray_placeholders()
    validate_platform_files()
    if errors:
        for e in errors:
            print(f"FAIL: {e}", file=sys.stderr)
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
