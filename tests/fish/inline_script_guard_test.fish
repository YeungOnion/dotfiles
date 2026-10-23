#!/usr/bin/env fish
# Tests for the inline-script-guard PreToolUse hook
# Run: fishtape tests/fish/inline_script_guard_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _hook $_repo_root/home/dot_claude/hooks/executable_inline-script-guard.py
set -gx ONE_OFF_SKILL $_repo_root/home/dot_claude/skills/one-off-scripts/SKILL.md

# Prints the hook's decision for a Bash command: deny, ask, or none.
function __guard_decision -a cmd
    set -l out (jq -cn --arg c $cmd '{tool_name:"Bash",tool_input:{command:$c}}' | python3 $_hook)
    if test -z "$out"
        echo none
    else
        echo $out | jq -r '.hookSpecificOutput.permissionDecision'
    end
end

@echo "Inline programs are denied"

for cmd in \
        "python3 -c 'print(1)'" \
        "python -c 'import os'" \
        "/usr/bin/python3 -I -c 'print(1)'" \
        "uv run python -c 'print(1)'" \
        "cd /tmp && python3 -c 'print(1)'" \
        "bun -e 'console.log(1)'" \
        "bun --eval 'console.log(1)'" \
        "node -e 'console.log(1)'" \
        "node -p '1+1'" \
        "npx tsx -e 'console.log(1)'" \
        "deno eval 'console.log(1)'" \
        "ruby -e 'puts 1'" \
        "perl -E 'say 1'" \
        "php -r 'echo 1;'" \
        "python3 - <<'EOF'
print(1)
EOF" \
        "node <<EOF
console.log(1)
EOF" \
        "cat prog.py | python3" \
        "cat prog.ts | bun -" \
        "bash -lc 'python3 -c \"print(1)\"'" \
        "ssh host 'node -e 1'"
    @test "deny: $(string split -m1 \n -- $cmd)[1]" (__guard_decision $cmd) = deny
end

@echo "Files, tests and read-only tools pass through"

for cmd in \
        "python3 scripts/report.py" \
        "python3 scripts/report.py -c 3" \
        "pytest -q" \
        "bun test" \
        "bun run build" \
        "bun scripts/x.ts" \
        "node dist/index.js" \
        "pnpm exec tsx scripts/q.ts data/v2.db 'PRAGMA integrity_check'" \
        "jq -r .a data.json" \
        "duckdb -c 'select 1'" \
        "grep -rn \"python3 -c\" ." \
        "echo hello"
    @test "none: $cmd" (__guard_decision $cmd) = none
end

@echo "The approval marker asks the user instead of denying"

@test "ask: ONE_OFF_APPROVED=1 python3 -c" (__guard_decision "ONE_OFF_APPROVED=1 python3 -c 'print(1)'") = ask

@test "deny reason carries the skill body, not its frontmatter" \
    (jq -cn '{tool_name:"Bash",tool_input:{command:"bun -e 1"}}' | python3 $_hook \
        | jq -r '.hookSpecificOutput.permissionDecisionReason' \
        | string match -q '*# One-off scripts*' && echo yes || echo no) = yes

@test "non-Bash tools are ignored" \
    (count (jq -cn '{tool_name:"Read",tool_input:{file_path:"python3 -c"}}' | python3 $_hook)) = 0
