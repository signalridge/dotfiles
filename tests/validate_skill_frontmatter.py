#!/usr/bin/env python3
"""Validate local Codex skill frontmatter with stdlib-only checks."""

from __future__ import annotations

import re
import sys
from pathlib import Path


REQUIRED_FIELDS = ("name", "description")


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def parse_frontmatter(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        fail(f"{path}: missing opening frontmatter delimiter")

    end = text.find("\n---\n", 4)
    if end == -1:
        fail(f"{path}: missing closing frontmatter delimiter")

    body = text[end + len("\n---\n") :].strip()
    if not body:
        fail(f"{path}: skill body is empty")

    fields: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if not line.strip() or line.startswith((" ", "-")):
            continue
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", line)
        if not match:
            fail(f"{path}: unsupported frontmatter line: {line}")
        key, value = match.groups()
        fields[key] = value.strip().strip("'\"")
    return fields


def validate_skill(path: Path) -> None:
    fields = parse_frontmatter(path)
    for field in REQUIRED_FIELDS:
        if not fields.get(field):
            fail(f"{path}: missing required frontmatter field: {field}")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {Path(argv[0]).name} SKILL_DIR_OR_ROOT", file=sys.stderr)
        return 2

    root = Path(argv[1])
    if root.name == "SKILL.md":
        skill_files = [root]
    else:
        skill_files = sorted(root.rglob("SKILL.md"))

    if not skill_files:
        fail(f"{root}: no SKILL.md files found")

    for skill_file in skill_files:
        validate_skill(skill_file)

    print(f"validated {len(skill_files)} skill file(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
