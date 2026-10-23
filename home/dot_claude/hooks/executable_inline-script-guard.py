#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""PreToolUse hook for Bash: deny inline interpreter programs, with the one-off-scripts skill as the reason.

- Inline code (python -c, node/bun -e, deno eval, heredocs or pipes into an interpreter) -> deny.
  Claude receives the skill body and decides: write a test, write a documented script, or ask.
- The same command prefixed with ONE_OFF_APPROVED=1 -> ask, so the user confirms in a permission prompt.
- Anything else -> no output, and the normal permission flow applies.

Errors fail open (exit 0, no decision): this hook steers, it isn't a security control.
ONE_OFF_SKILL overrides the skill path (tests use it).
"""

import json
import os
import re
import sys
from pathlib import Path

SKILL = Path(os.environ.get("ONE_OFF_SKILL", Path.home() / ".claude/skills/one-off-scripts/SKILL.md"))

# Where a command can start: line start, after a shell operator, or inside `bash -c '...'` / `ssh host '...'`.
START = r"""(?:^|[;&|(`{\n]|\$\(|\b(?:then|do|else)\b|-\w*c\s+['"]|\bssh\b[^'"\n]*['"])\s*"""
# Wrappers that run the next word as the command.
PREFIX = r"(?:(?:sudo|exec|time|nice|command|env|\w+=\S*|uv\s+run|npx|bunx|pnpm\s+(?:exec|dlx)|npm\s+exec)\s+)*"
OPTS = r"(?:\s+--?[\w-]+(?:=\S+)?)*"  # options only: a positional argument (a script file) ends the match

FAMILIES = {
    r"python(?:3(?:\.\d+)?)?|pypy3?": r"-c",
    r"node|nodejs|bun|tsx|ts-node": r"-e|--eval|-p|--print",
    r"ruby|lua(?:jit)?|julia|Rscript": r"-e",
    r"perl": r"-[eE]",
    r"php": r"-r",
}
STDIN_INTERP = r"python(?:3(?:\.\d+)?)?|pypy3?|node|nodejs|bun|deno|tsx|ts-node|ruby|perl|php|Rscript|julia|lua(?:jit)?"

PATTERNS = [
    re.compile(START + PREFIX + rf"(?:\S*/)?(?:{interp}){OPTS}\s+(?:{flags})(?:\s|=|$)") for interp, flags in FAMILIES.items()
] + [
    re.compile(START + PREFIX + r"(?:\S*/)?deno\s+eval\b"),
    # heredoc straight into an interpreter: python3 - <<'EOF', node <<EOF
    re.compile(START + PREFIX + rf"(?:\S*/)?(?:{STDIN_INTERP}){OPTS}(?:\s+-)?\s*<<"),
    # pipe into an interpreter that reads its program from stdin: cat x | python3, ... | bun -
    re.compile(r"\|\s*" + PREFIX + rf"(?:\S*/)?(?:{STDIN_INTERP}){OPTS}(?:\s+-)?\s*(?:$|[;&|)'\"\n])"),
]
APPROVED = re.compile(r"(?:^|[;&|\n]\s*|\s)ONE_OFF_APPROVED=1\s")


def decision(kind: str, reason: str) -> None:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse", "permissionDecision": kind, "permissionDecisionReason": reason}}))


def skill_body() -> str:
    try:
        text = SKILL.read_text()
    except OSError:
        return "See the one-off-scripts skill: prefer a test, then a documented script in scripts/, then ask the user."
    return re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S).strip()


def main() -> None:
    data = json.loads(sys.stdin.read())
    if data.get("tool_name") != "Bash":
        return
    command = data.get("tool_input", {}).get("command", "")
    if not any(p.search(command) for p in PATTERNS):
        return
    if APPROVED.search(command):
        decision("ask", "Claude wants to run an inline script (marked ONE_OFF_APPROVED=1). Its reply should say why a test or script doesn't fit.")
    else:
        decision("deny", "Inline script blocked by inline-script-guard. Choose a better form, or ask:\n\n" + skill_body())


if __name__ == "__main__":
    try:
        main()
    except Exception:
        sys.exit(0)
