#!/usr/bin/env python3
"""Validate the Performance Skill markdown rule registry.

This script intentionally performs local structural validation only.
LLM/web fetching remains the responsibility of the active agent runtime.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RULE_FILE = ROOT / "references" / "performance-rule-list.md"
SOURCE_FILE = ROOT / "references" / "performance-source-registry.md"
PATH_RULES_FILE = ROOT / "references" / "perf-path-rules.json"

RULE_ID_RE = re.compile(r"\|\s*\[[x~ ]\]\s*\|\s*(PERF-[A-Z0-9-]+)\s*\|")
URL_RE = re.compile(r"https?://[^)\s>]+")
SOURCE_ID_RE = re.compile(r"\bREF-[A-Z0-9-]+\b")
GROUP_RE = re.compile(r'"groups"\s*:\s*\[([^\]]*)\]')


def main() -> int:
    errors: list[str] = []

    if not RULE_FILE.exists():
        errors.append(f"Missing: {RULE_FILE}")
    if not SOURCE_FILE.exists():
        errors.append(f"Missing: {SOURCE_FILE}")
    if not PATH_RULES_FILE.exists():
        errors.append(f"Missing: {PATH_RULES_FILE}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    rules_text = RULE_FILE.read_text(encoding="utf-8")
    source_text = SOURCE_FILE.read_text(encoding="utf-8")

    rule_ids = RULE_ID_RE.findall(rules_text)
    duplicates = sorted({rid for rid in rule_ids if rule_ids.count(rid) > 1})
    if duplicates:
        errors.append("Duplicate rule IDs: " + ", ".join(duplicates))

    if not rule_ids:
        errors.append("No PERF rule IDs found")

    source_ids = set(SOURCE_ID_RE.findall(source_text))
    for line_no, line in enumerate(rules_text.splitlines(), start=1):
        if "| PERF-" not in line:
            continue
        refs = SOURCE_ID_RE.findall(line)
        missing = [ref for ref in refs if ref not in source_ids]
        if missing:
            errors.append(
                f"Line {line_no}: unknown source ID(s): {', '.join(missing)}"
            )

    urls = URL_RE.findall(source_text)
    if len(urls) < 8:
        errors.append("Expected at least 8 trusted/detection URLs in source registry")

    required_sections = [
        "## Java",
        "## Spring Boot / JPA / Hibernate",
        "## React / JavaScript",
        "## JavaScript",
        "## Frontend loading / browser",
        "## Evidence / methodology",
        "## Explicit non-rules",
        "## Dynamic additions",
    ]
    for section in required_sections:
        if section not in rules_text:
            errors.append(f"Missing rule-registry section: {section}")

    # perf-path-rules.json: every rule family prefix must resolve to a real PERF ID.
    all_ids = set(re.findall(r"PERF-[A-Z0-9-]+", rules_text))
    path_rules_text = PATH_RULES_FILE.read_text(encoding="utf-8")
    prefixes: list[str] = []
    for match in GROUP_RE.findall(path_rules_text):
        prefixes.extend(part.strip().strip('"') for part in match.split(",") if part.strip())
    if not prefixes:
        errors.append("perf-path-rules.json: no rule groups found")
    for prefix in prefixes:
        if not any(rid.startswith(prefix + "-") for rid in all_ids):
            errors.append(f"perf-path-rules.json: group '{prefix}' matches no PERF rule ID")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print(f"OK: {len(rule_ids)} active/selected registry entries validated")
    print(f"OK: {len(urls)} URLs found in source registry")
    print(f"OK: {len(prefixes)} path-rule groups resolve to registry IDs")
    print("OK: rule sections and source IDs are structurally valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
