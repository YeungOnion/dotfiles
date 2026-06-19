#!/bin/bash
# Orchestration test: verify chezmoi's execution plan contains all scripts in correct order.
# Uses an isolated state file for the dry-run so results reflect a fresh-machine view
# without touching or needing to restore the real state.
set -uo pipefail

SCRIPTS=(
    "01-bootstrap-package-managers"
    "02-install-packages"
    "03-bat-symlink"
    "04-fish-universal"
)

fail=0
ok()   { echo "ok: $*"; }
report_fail() { echo "FAIL: $*"; fail=1; }

# Use an isolated state file: run_onchange_ scripts are tracked in entryState (by
# destination path), not just scriptState, so clearing scriptState alone would miss them.
# An isolated non-existent path lets chezmoi create a fresh BoltDB, giving a
# fresh-machine view without touching real state. mktemp would create an empty
# (invalid BoltDB) file, so we use a PID-unique path instead.
_state_file="/tmp/chezmoi-orch-state-$$.boltdb"
trap 'rm -f "$_state_file"' EXIT

# Capture the plan; chezmoi apply --dry-run --verbose emits diff --git lines per script
plan=$(chezmoi apply --persistent-state "$_state_file" --dry-run --verbose 2>&1)

# Assert each expected script appears in the plan
for script in "${SCRIPTS[@]}"; do
    if echo "$plan" | grep -qF ".chezmoiscripts/${script}.sh"; then
        ok "$script present in plan"
    else
        report_fail "$script missing from plan"
    fi
done

# Assert correct execution order: each script's diff header appears before the next
for i in "${!SCRIPTS[@]}"; do
    [[ $i -eq 0 ]] && continue
    prev="${SCRIPTS[$((i-1))]}"
    curr="${SCRIPTS[$i]}"
    line_prev=$(echo "$plan" | grep -nF ".chezmoiscripts/${prev}.sh" | head -1 | cut -d: -f1)
    line_curr=$(echo "$plan" | grep -nF ".chezmoiscripts/${curr}.sh" | head -1 | cut -d: -f1)
    if [[ -n "$line_prev" && -n "$line_curr" && "$line_prev" -lt "$line_curr" ]]; then
        ok "$prev before $curr"
    else
        report_fail "$prev not before $curr (lines: ${line_prev:-missing} vs ${line_curr:-missing})"
    fi
done

# Assert no unexpected scripts appear (catches stray scripts without numeric prefix)
unexpected=$(echo "$plan" | grep '\.chezmoiscripts/' \
    | sed 's|.*\.chezmoiscripts/||; s|\.sh.*||' \
    | grep -vE "^(01-bootstrap-package-managers|02-install-packages|03-bat-symlink|04-fish-universal)$" \
    || true)
if [[ -z "$unexpected" ]]; then
    ok "no unexpected scripts in plan"
else
    report_fail "unexpected scripts in plan: $unexpected"
fi

exit $fail
