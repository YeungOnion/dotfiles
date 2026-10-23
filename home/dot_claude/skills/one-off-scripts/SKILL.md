---
name: one-off-scripts
description: Use before writing an inline or throwaway script (python -c, node/bun -e, heredoc programs, data-reshaping shell loops) - decide between a test, a documented script, or asking.
---

# One-off scripts

An inline program is code nobody can review, rerun or test. Choose, in order:

1. **It checks behavior → write a test.**
   - Local code: a test in the project's own suite.
   - An external dependency's behavior: a `test_deps` test, marked skip (pytest `@pytest.mark.skip`, cargo `#[ignore]`, bun `test.skip`).
2. **It takes parameters and will be rerun → a documented script** in the project's `scripts/` directory. Give it a header comment with its purpose, usage and arguments, and run it as a file (`bun scripts/x.ts`, `uv run scripts/x.py`).
3. **It's a read-only query → use read-oriented tools inline.** `jq`, `duckdb`, `grep` and `awk` one-liners are fine.
4. **None of these fits → ask.** Explain in your reply what the code does and why a test or script doesn't fit. Then rerun the command prefixed with `ONE_OFF_APPROVED=1`: the hook turns it into a permission prompt, so the user decides. The prefix is a request for approval, not approval.

## Misuse examples

- `python -c "import my_project; ..."` → a test in the project.
- `python -c "import external_module; ..."` → a `test_deps` test, marked skip.
- `bun -e "await fetch(...)"` to check an API → a `test_deps` test, or a documented script if it takes arguments.
- `node - <<'EOF' ... EOF` to reshape JSON → `jq` or `duckdb`.

## What the hook flags

`inline-script-guard.py` denies Bash commands that run an interpreter on inline code, and sends this skill back as the reason:
- `-c`, `-e`/`-E`, `--eval`, `-p`/`--print` and `php -r` flags, and `deno eval`
- heredocs and pipes into python, node, bun, deno, tsx, ts-node, ruby, perl, php, Rscript, julia and lua

The hook also catches these inside `bash -c '...'` and `ssh host '...'`. Running a file (`bun scripts/x.ts`, `pytest`, `node dist/index.js`) isn't flagged.
