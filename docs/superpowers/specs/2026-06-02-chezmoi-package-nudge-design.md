# Chezmoi Package Nudge — Design Spec

## Problem

There are two valid paths for installing a package:

1. **Transient** — `brew install foo` / `cargo binstall foo` / `uv tool install foo`. Fast, no chezmoi involvement. Package won't appear on a fresh machine bootstrap.
2. **Declarative** — edit the relevant chezmoiscript, then `chezmoi apply`. Persists across machines.

Currently neither path prompts the user to consider the other. There is no cue when using the transient path to ask "should this be on all machines?", and no reminder after editing a script to apply the change.

## Goal

Add print-only, non-blocking nudges in fish that surface the decision point without changing either path's mechanics or requiring user input.

## Scope

Two nudges, one new file, one script rename.

---

## Changes

### 1. Rename `run_onchange_install-py.sh.tmpl` → `run_onchange_install-uv.sh.tmpl`

The script installs uv and uv-managed tools. The `-py` suffix is misleading. Rename to align tool name with script name.

File: `home/.chezmoiscripts/run_onchange_install-py.sh.tmpl` → `run_onchange_install-uv.sh.tmpl`

No content changes.

### 2. New file: `home/private_dot_config/private_fish/conf.d/chezmoi_nudge.fish`

Defines one function: `__chezmoi_nudge --on-event fish_postexec`.

---

## Nudge Behaviour

### Branch 1 — Install nudge (lexical, instant)

**Trigger:** command string contains `\b(install|binstall)\b` AND has known manager prefix in command position.

commands
- brew
- cargo
- uv tool

**Output** (one line, to stderr so it doesn't pollute command output):
```
chezmoi?: hx (chezmoi source-path)/.chezmoiscripts/
```

No subprocess, no filesystem access. Pure string matching on `$argv[1]`.

### Branch 2 — Apply reminder (path check + status)

**Trigger:** commandline command is a known editor (`hx`, `vim`, `nvim`, `nano`) AND contains the substring `.chezmoiscripts/` (matches both absolute paths and relative paths used after `chezmoi source-path`).

**Check:** `chezmoi status 2>/dev/null | string match -rq '^\s*R.*chezmoiscripts'`

**Output** (one line, to stderr, only if check matches):
```
chezmoi: script changes pending → chezmoi apply
```

Cost: one `chezmoi status` call (~220ms), synchronous, before the next prompt draws. No user input required.

---

## Implementation notes

- Both branches must not modify `$status` — the exit code of the previous command must be preserved across the handler.
- Branch 2 runs `chezmoi status` synchronously. A background job would avoid the delay but risks printing after the prompt has drawn; synchronous is preferable.
- The function name uses `__` prefix (private convention) since it is not intended for direct invocation.
- Stderr output keeps nudge lines visually distinct from command stdout and separable in scripts.

---

## Non-goals

- No user input or confirmation prompts.
- No tracking of transiently-installed packages.
- No nudge for `brew upgrade`, `cargo update`, `uv tool upgrade`, or uninstall commands — maintenance operations are not decision points.
- No nudge for non-script chezmoi source edits (managed dotfiles handled separately by `fisher_chezmoi_sync.fish`).
