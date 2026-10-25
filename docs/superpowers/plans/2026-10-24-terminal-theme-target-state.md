# Terminal theme target state Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The light/dark theme is a chosen *target* stored in a file. You set it from the command line or a script, or forward it over `cc`. The Windows poller only records what Windows says and never changes the target. Shells, tmux and new Claude Code sessions follow the target, and a tmux config reload keeps it.

**Architecture:** Three states, each with one kind of writer:

| State | Where | Written by |
|---|---|---|
| target | `$XDG_STATE_HOME/terminal-theme/target` (default `~/.local/state/…`) | `terminal_theme light\|dark\|toggle\|apply\|system`, `cc` forwarding |
| system | `…/terminal-theme/system` | the poller only (`__terminal_theme_poll_sync`) |
| applied | universal `terminal_theme`, tmux `@thm_*` palette | the assignment step only |

Every mutating subcommand ends in one of two assignments, `light` or `dark`. An assignment:
1. writes the target file;
2. sources the matching tmux palette (`palette_light.conf` or `palette_dark.conf`, picked by a `switch` and never built from the value);
3. publishes the universal variable through `__terminal_theme_publish`, the only code that runs `set -U terminal_theme`.

`toggle`, `apply` and `system` read a file and call an assignment. An unreadable or invalid target is reset to dark, with a warning on stderr. A missing or invalid system file changes nothing and prints nothing. Per-shell effects stay in the existing `--on-variable` handler (BAT_THEME, LS_COLORS); a `claude` wrapper adds Claude Code's theme per process with `--settings`.

**Tech Stack:** fish 4.x + fishtape, tmux 3.8, chezmoi 2.73 (`create_`, `private_`, `.chezmoiremove`), Claude Code 2.1.310, systemd user units.

**Spec:** decisions agreed in session 2026-10-24 (target vs system state, option (b): the poller records only).

## Background (signals measured before planning, 2026-10-24)

- **The poller overwrites manual settings.** `__terminal_theme_poll_sync` runs every 60s and writes `set -U terminal_theme` from the registry whenever it differs. Any manual or forwarded value reverts within a minute.
- **A tmux reload reverts to Windows.** `theme.conf` runs `tmux-theme-sync.sh` on every load, and that script reads `reg.exe` again. It also rewrites `~/.claude/themes/custom.json`, which Claude Code doesn't use: `~/.claude/settings.json` has `"theme": "light"` (written by `/theme`), and `custom.json` was last written 2026-10-17.
- **The palettes differ only in `@thm_*` options.** `theme.conf` reads those through `#{@thm_*}`, so sourcing a palette file recolors the status bar, borders and messages.
- **tmux `run-shell` resolves `fish`** (`/home/linuxbrew/.linuxbrew/bin/fish`; the server's PATH includes linuxbrew). `XDG_STATE_HOME` is unset in both tmux and the login shell.
- **Claude Code has no theme environment variable.** The only `*THEME*` strings in the binary are `THEME_NOTIFY`, `DECISION_THEME_SCRIPT` and `BAT_THEME`.
- **Claude Code honors `theme` from `--settings`.** `tests/fish/deps/claude_settings_theme_test.fish` passes 3/3: dark renders the same colors twice (the control), and dark and light render differently. `--settings` also works with `--version` and with subcommands (`claude --settings '{…}' mcp --help`).
- **Not tested, by decision:** whether `/theme` inside a session started with `--settings` takes effect (flag settings outrank user settings). `/theme` is user-triggered, so the user accepted this (2026-10-24).
- **The SSH session reaches tmux through Tailscale SSH** (`tailscaled be-child ssh --login-shell=…/fish`). The host's fish parses the remote command string. `string escape` keeps a forwarded value as one literal argument; `ssh_config_test` covers this.

## Global Constraints

- No inline scripting. Tests go in `tests/fish/`; Claude Code behavior is checked in `tests/fish/deps/`, which `make test-unit` doesn't run.
- Use `trash`, never `rm`.
- `make test-unit` is read-only against the live home. Every theme test runs a child `fish` with temporary `XDG_CONFIG_HOME`, `XDG_STATE_HOME` and `TMUX_TMPDIR`, `TMUX` unset, and a private tmux server (`tmux -f /dev/null`). The live uvar, target file and tmux server are never touched.
- Only `__terminal_theme_publish` contains `set -U terminal_theme`. A static test enforces this.
- Values are checked with `switch`/`contains` before use. Never interpolate a state value into a path, a tmux command or JSON.
- From an agent shell (umask 0002), run applies as `umask 022; chezmoi apply <named targets>` (CLAUDE.md).
- No absolute home paths (`/home/<user>`) in committed files.
- Commit messages end with:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01JvGkfoNcg812LX4zYaz84t
  ```

## Domain

- **Target theme:** what you want. Changed only by explicit actions: a CLI call, `cc` forwarding, or `system` (copy what Windows says, on request).
- **System theme:** what Windows says. Observed only. Exists only on WSL machines with the poller.
- **Applied theme:** the target pushed out. Shared effects (target file, tmux palette, uvar) run once per assignment. Per-process effects (BAT_THEME, LS_COLORS, Claude Code's `--settings`) are computed from the uvar, in each shell or each launch.

## Review Focus

- **The poller never changes target or applied state** → Task 4: "poll leaves target and uvar untouched".
- **A hostile target is never sourced:** a target of `../../x`, pointing at a planted conf file, must not run it → Task 2: "a target path is never sourced".
- **Bad target data is fixed to dark:** `blue`, empty, garbage, two lines, padding, missing, unreadable (or a directory in its place) → `apply` and `toggle` rewrite the file to `dark` and apply dark (Task 3). `terminal_theme` with no argument stays read-only: it prints nothing for bad data and leaves the file alone. The fix happens at the next `apply`, `toggle` or tmux reload.
- **Bad system data never changes anything:** `blue`, empty, garbage, two lines, missing, unreadable, a directory → `system` leaves the target file (contents and mtime), the uvar and the tmux palette unchanged and prints nothing (Task 3).
- **`set -U terminal_theme` appears only in `__terminal_theme_publish`** → Task 2 static test.
- **A tmux reload keeps the target** → Task 5: a private server sources the real `theme.conf` with the target set to light.
- **No tmux server is not an error** → Task 2 and Task 3: an assignment with no server exits 0 and writes the target.

---

### Task 1: State file primitives

**Files:** Create `home/private_dot_config/private_fish/functions/__terminal_theme_state_file.fish`, `functions/__terminal_theme_read.fish`, `functions/__terminal_theme_write.fish`. Test: create `tests/fish/terminal_theme_state_test.fish`.

- [ ] **Step 1: Write failing tests** (sourcing the three files in the test process is safe: they touch only the file paths they're given)
  - `state_file target` prints `$XDG_STATE_HOME/terminal-theme/target`; with `XDG_STATE_HOME` unset it prints `~/.local/state/terminal-theme/target` (expanded). `state_file system` likewise; any other name returns 2.
  - `read` prints `light`/`dark` for files containing exactly that word plus a trailing newline; returns 1 and prints nothing, with no stderr, for:
    - a missing file
    - an empty file
    - `blue`
    - `garbage`
    - `light\nx` (two lines)
    - ` light ` (padding)
    - `../../x`
    - a file that can't be read (`chmod 000`)
    - a directory at the path
  - `write <file> light` creates missing parent directories with mode 700 and writes `light\n`. `write <file> purple` returns 2 and leaves an existing file unchanged. The write is atomic: a temp file next to the target, then `mv`. `write` replaces an unreadable (`chmod 000`) file, leaving it mode 644. With a directory at the path it returns 1 with an error and creates nothing inside it (`mv` alone would move the temp file into the directory and report success).
- [ ] **Step 2: Run** `fishtape tests/fish/terminal_theme_state_test.fish` and confirm the new tests fail.
- [ ] **Step 3: Implement.** `__terminal_theme_read -a file`: `test -f $file; or return 1`, then `set -l v (string collect < $file)`, `contains -- "$v" light dark; or return 1`, `echo $v`. Command substitution strips the single trailing newline, and a second line keeps `$v` from matching. `__terminal_theme_write -a file theme`: `contains -- "$theme" light dark; or return 2`; `test -d $file` → error to stderr, return 1; then `mkdir -p -m 700` the parent, `printf '%s\n' $theme > $file.tmp.$fish_pid`, `chmod 644` it, and `mv -f` it over the file, trashing the temp file if `mv` fails. Use `-f` rather than GNU-only `-T`: the repo also targets macOS, and the directory check already covers what `-T` would.
- [ ] **Step 4: Run the tests** and confirm they pass.
- [ ] **Step 5: Commit** `feat(fish): terminal theme state files`

### Task 2: Effects: validated tmux palette, sole uvar writer

**Files:** Create `functions/__terminal_theme_tmux.fish` and `functions/__terminal_theme_publish.fish`. Test: extend `terminal_theme_state_test.fish`.

**Test harness** (from this task on): a helper `_tt_env` builds a temp root:
- `cfg/fish/functions` and `cfg/fish/conf.d` symlink to the source directories;
- `cfg/tmux/conf.d` symlinks to `home/private_dot_config/tmux/conf.d`;
- `state/` and `tmux/` are empty.

`_tt <fish code>` runs `env -u TMUX XDG_CONFIG_HOME=… XDG_STATE_HOME=… TMUX_TMPDIR=… fish -c <code>`. Plain `fish`, not `--no-config`, because universals must load; the temp `XDG_CONFIG_HOME` has no `config.fish`. `_tmux_up` starts a private server with `tmux -f /dev/null new-session -d` under the same `TMUX_TMPDIR`, and teardown runs `kill-server` and `trash`.

- [ ] **Step 1: Write failing tests**
  - `__terminal_theme_tmux light` against a private server makes `tmux show -gv @thm_theme_name` print `light`; `dark` likewise.
  - With no server running it returns 0 and prints nothing.
  - `__terminal_theme_tmux '../../x'` (with a planted `x.conf` that sets `@pwned`) returns 1, writes an error to stderr, and leaves `@pwned` unset.
  - `__terminal_theme_publish light` sets the universal (read back by a second `_tt` call); `purple` returns 1 and doesn't write.
  - Publishing the current value doesn't fire `--on-variable terminal_theme`; changing it fires once (handler counter inside `_tt`).
  - (The static "only publish runs `set -U`" test moved to Task 4: the old setter and the poller still run `set -U` until Tasks 3 and 4 remove them.)
- [ ] **Step 2: Run the tests** and confirm they fail.
- [ ] **Step 3: Implement.**
  - `__terminal_theme_tmux -a theme`: `switch $theme` sets `-f conf palette_light.conf` / `palette_dark.conf`; anything else prints an error to stderr and returns 1. Then `tmux show-options -gqv status >/dev/null 2>&1; or return 0` (measured: `has-session` fails while `theme.conf` loads at server start, and a socket file outlives `kill-server`; `show-options` works in the first case and fails in the second), then `tmux source-file $conf_root/tmux/conf.d/$conf`, with `conf_root` set to `$XDG_CONFIG_HOME` or `~/.config`.
  - `__terminal_theme_publish -a theme`: `switch` with literal `set -U terminal_theme light` / `set -U terminal_theme dark` lines, each guarded by `test "$terminal_theme" != light`; anything else returns 1.
- [ ] **Step 4: Run the tests** and confirm they pass.
- [ ] **Step 5: Commit** `feat(fish): validated tmux palette and terminal_theme publisher`

### Task 3: `terminal_theme` CLI on the target state

**Files:** Rewrite `functions/terminal_theme.fish`. Create `functions/__terminal_theme_assign.fish`. Delete `functions/__terminal_theme_set.fish` and add `.config/fish/functions/__terminal_theme_set.fish` to `home/.chezmoiremove` in the same commit. Delete `tests/fish/terminal_theme_set_test.fish`. Update `completions/terminal_theme.fish` (add `apply` and `system`). Test: extend `terminal_theme_state_test.fish`.

Behavior (all mutating subcommands print nothing on success, because tmux `run-shell` would show any output):

```fish
function terminal_theme --description 'print or set the target light/dark theme: terminal_theme [light | dark | toggle | apply | system]'
    if test (count $argv) -gt 1
        echo "usage: terminal_theme [light | dark | toggle | apply | system]" >&2
        return 2
    end
    switch "$argv[1]"
        case ''
            __terminal_theme_read (__terminal_theme_state_file target)
        case light
            __terminal_theme_assign light
        case dark
            __terminal_theme_assign dark
        case toggle
            switch (__terminal_theme_read (__terminal_theme_state_file target))
                case light; terminal_theme dark
                case dark; terminal_theme light
                case '*'; __terminal_theme_assign_reset
            end
        case apply
            switch (__terminal_theme_read (__terminal_theme_state_file target))
                case light; terminal_theme light
                case dark; terminal_theme dark
                case '*'; __terminal_theme_assign_reset
            end
        case system
            # no system state (no poller, or not WSL): no report, no change
            switch (__terminal_theme_read (__terminal_theme_state_file system))
                case light; terminal_theme light
                case dark; terminal_theme dark
            end
        case '*'
            echo "usage: terminal_theme [light | dark | toggle | apply | system]" >&2
            return 2
    end
end
```

- `__terminal_theme_assign -a theme`: `__terminal_theme_write (…target) $theme; and __terminal_theme_tmux $theme; and __terminal_theme_publish $theme`.
- `__terminal_theme_assign_reset`, in the same file: prints `terminal_theme: target state was invalid, reset to dark` to stderr, then `__terminal_theme_assign dark`.

- [ ] **Step 1: Write failing tests** (all through `_tt`)
  - `light` / `dark` write the target file, set the uvar and print nothing on stdout.
  - No argument prints the target. With an invalid target it prints nothing, returns 1 and leaves the file unchanged (reading is read-only).
  - `toggle`: light → dark and dark → light.
  - `apply`: target light with a stale uvar dark leaves the uvar at light.
  - **Bad target data is fixed to dark.** For each of these target contents:
    - `blue`
    - empty
    - `garbage`
    - `light\nx` (two lines)
    - ` light ` (padding)
    - a missing file
    - a file that can't be read (`chmod 000`)
    - a directory where the file should be

    both `apply` and `toggle`:
    - leave the target file containing exactly `dark\n` (readable again; the atomic `mv` replaces an unreadable file);
    - set the uvar to `dark` and, with a private server, `@thm_theme_name` to `dark`;
    - print the reset warning on stderr and exit 0.

    Exception: with a directory in the file's place, the reset exits 1 with an error on stderr. It leaves the directory, the uvar and tmux unchanged, and puts no file inside the directory. (`mv tmp dir` would succeed by moving the file *into* the directory, so `__terminal_theme_write` refuses a directory path first. Task 1.)
  - **Bad system data leaves everything unchanged.** Start from target `light`, uvar `light` and private-server `@thm_theme_name` `light`. For each of these system file contents:
    - `blue`
    - empty
    - `garbage`
    - two lines
    - a missing file
    - a file that can't be read (`chmod 000`)
    - a directory where the file should be

    `system`:
    - leaves the target file byte-identical and its mtime unchanged;
    - leaves the uvar `light` and `@thm_theme_name` `light`;
    - prints nothing and exits 0.
  - `system`: a system file of `dark` sets the target to dark.
  - A bad argument or two arguments: status 2, usage on stderr, no file written.
  - With a private tmux server, `terminal_theme light` changes `@thm_theme_name` to `light`.
  - With no server, it still exits 0 and writes the target.
- [ ] **Step 2: Run the tests** and confirm they fail.
- [ ] **Step 3: Implement**, delete the old setter and its test, and add the `.chezmoiremove` line.
- [ ] **Step 4: Run the tests** and confirm they pass.
- [ ] **Step 5: Commit** `feat(fish): terminal_theme sets a target state file`

### Task 4: Poller records the system state only

**Files:** Modify `functions/__terminal_theme_poll_sync.fish`, `scripts/executable_terminal-theme-poll.fish` and the `Description=` in `systemd/user/terminal-theme-poll.service`. Test: rewrite the poll_sync section of `tests/fish/terminal_theme_poll_test.fish`; keep its systemd unit tests.

- [ ] **Step 1: Write failing tests**
  - `__terminal_theme_poll_sync <file> echo light` writes `light` to the file and returns 0.
  - The same value again leaves the file untouched (same mtime) and returns 0.
  - `unknown`, no output, or `garbage` → no write, return 1.
  - In `_tt`, with target `dark` and uvar `dark`, polling `echo light` leaves both unchanged.
- [ ] **Step 2: Run the tests** and confirm they fail.
- [ ] **Step 3: Implement.** `__terminal_theme_poll_sync -a file`, with the query in `$argv[2..]`. Compare with `__terminal_theme_read $file`, and write with `__terminal_theme_write` only on a change. The poll script becomes `__terminal_theme_poll_sync (__terminal_theme_state_file system) __terminal_theme_query`. The unit's Description becomes "record Windows light/dark theme as terminal-theme system state". Update the header comments in both files to match.
- [ ] **Step 4: Run the tests** and confirm they pass.
- [ ] **Step 5: Commit** `fix(fish): poller records system theme, no longer overwrites terminal_theme`

### Task 5: tmux config load applies the target

**Files:** Modify `home/private_dot_config/tmux/conf.d/theme.conf` line 5. Delete `home/private_dot_config/tmux/scripts/executable_tmux-theme-sync.sh` and add `.config/tmux/scripts/tmux-theme-sync.sh` to `home/.chezmoiremove` in the same commit. Test: create `tests/fish/tmux_theme_test.fish`.

- [ ] **Step 1: Write failing tests**
  - `theme.conf` contains `run-shell 'fish -c "terminal_theme apply"'` and no `tmux-theme-sync`.
  - In the `_tt_env` temp root with target `light`, start a private server with `-f` pointing at the source `theme.conf`, with the temp XDG variables in the server's environment. Then `show -gv @thm_theme_name` prints `light`.
  - `source-file theme.conf` again (a reload) still prints `light`.
  - With target `dark` the same check prints `dark`.
- [ ] **Step 2: Run the tests** and confirm they fail.
- [ ] **Step 3: Implement**: replace the `run-shell` line and delete the script.
- [ ] **Step 4: Run the tests** and confirm they pass.
- [ ] **Step 5: Commit** `feat(tmux): config load applies terminal_theme target, drop tmux-theme-sync`

### Task 6: Claude Code theme per launch

**Files:** Modify `conf.d/terminal_theme.fish` (add `__terminal_theme_claude_name`). Create `functions/claude.fish`. Test: extend `tests/fish/terminal_theme_test.fish`. Add `make test-deps` running `tests/fish/deps/*.fish` (the file already exists, uncommitted).

- [ ] **Step 1: Write failing tests**
  - Name mapping: `light` → `$CLAUDE_THEME_LIGHT`, or `light` when unset; `dark` → `$CLAUDE_THEME_DARK`, or `dark`; anything else prints nothing. This mirrors the bat and vivid tests.
  - Wrapper, run with a stub `claude` that prints its arguments, first on PATH in a child `fish --no-config`. First assert the stub is what `command -v claude` resolves, and skip otherwise (CLAUDE.md rule).
    - With `terminal_theme` light, the arguments start with `--settings {"theme":"light"}`, followed by the user's own arguments unchanged.
    - With it unset, there's no `--settings`.
    - With `CLAUDE_THEME_DARK='x"y'`, there's no `--settings` and a warning goes to stderr. Theme names must match `^[a-z0-9:-]+$`, so a quote can't break the JSON.
- [ ] **Step 2: Run the tests** and confirm they fail.
- [ ] **Step 3: Implement** `function claude --wraps claude`: compute the name, check it with `string match -rq '^[a-z0-9:-]+$'`, then `command claude --settings "{\"theme\":\"$name\"}" $argv`, or `command claude $argv` when there's no valid name.
- [ ] **Step 4: Run the tests and `make test-deps`** and confirm they pass.
- [ ] **Step 5: Commit** `feat(fish): claude follows terminal_theme via --settings` (include the deps test and the Makefile target)

### Task 7: `cc` forwards the client's target

**Files:** Modify `home/private_dot_config/private_fish/aliases.fish` line 15. Test: update the cc tests in `tests/fish/ssh_config_test.fish`.

- [ ] **Step 1: Update the tests.** The abbreviation contains `"terminal_theme $(string escape -- "$(terminal_theme)"); tmux new-session -A -s cc"`. The injection test keeps its hostile value. The forwarded value now comes from the client's target file, read by `terminal_theme` with no argument.
- [ ] **Step 2: Run the tests** and confirm they fail.
- [ ] **Step 3: Implement.** An invalid client target prints nothing, so the remote runs `terminal_theme ''`, which only prints its own target before tmux takes the screen.
- [ ] **Step 4: Run the tests** and confirm they pass.
- [ ] **Step 5: Commit** `feat(fish): cc forwards the client's target theme`

### Task 8: chezmoi seeds the target file

**Files:** Create `home/dot_local/state/private_terminal-theme/create_target` containing `dark`. Test: create `tests/fish/terminal_theme_seed_test.fish`.

`create_` is chezmoi's built-in "create if missing, never overwrite", so it does what a seeding script would without running code. `private_` gives the directory mode 700.

- [ ] **Step 1: Write failing tests.** Apply only that target, with the commands `chezmoi --config chezmoi.test.toml --source home --destination $tmp --persistent-state $tmp/state.boltdb apply --no-tty $tmp/.local/state/terminal-theme/target`, under `umask 022` in a child fish. Check:
  - the file contains `dark` and its directory has mode 700;
  - after writing `light` into it, a second apply leaves `light`.
- [ ] **Step 2: Run the tests** and confirm they fail.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests** and confirm they pass.
- [ ] **Step 5: Commit** `feat(chezmoi): seed terminal-theme target state`

### Task 9: Test wiring and integration checks

**Files:** `Makefile` and `tests/integration.sh`.

- [ ] In `test-unit`, replace `terminal_theme_set_test.fish` with `terminal_theme_state_test.fish`, `tmux_theme_test.fish` and `terminal_theme_seed_test.fish`.
- [ ] In `integration.sh`'s deployed list, add `~/.local/state/terminal-theme/target` and the new function files. Assert the target directory's mode is 700 and that `tmux-theme-sync.sh` isn't deployed.
- [ ] Run `make test-unit` and confirm all tests pass. Report any failures with their output.
- [ ] Commit `test: wire terminal theme state tests`

### Task 10: Docs and memory

- [ ] In `CLAUDE.md`, add a section "terminal theme: target, system, applied" with:
  - the three-state table;
  - "only `__terminal_theme_publish` runs `set -U terminal_theme`; change it with `terminal_theme`, never `set -U`";
  - "the poller writes only `system`";
  - "`theme.conf` runs `terminal_theme apply`";
  - "Claude Code's theme comes from the `claude` wrapper's `--settings` (no env var exists)";
  - "`tests/fish/deps/` checks Claude Code behavior (`make test-deps`, manual)";
- [ ] At the top of `docs/superpowers/plans/2026-07-18-terminal-theme-poll.md`, add a note that the poller's uvar write was replaced by this plan.
- [ ] Update memory `fish-light-dark-theme-plan`: the poller now records system state only; the target file drives everything.
- [ ] Commit `docs: terminal theme target state`

### Task 11: Roll out on this machine

- [ ] `umask 022; chezmoi diff --no-pager </dev/null`, filtered to content lines. Confirm it shows only this plan's files and the two `.chezmoiremove` deletions.
- [ ] `umask 022; chezmoi apply` on the named targets, then confirm with `stat -c %a`.
- [ ] `terminal_theme apply`, then check `tmux show -gv @thm_theme_name` against `terminal_theme`.
- [ ] Wait more than 60s with Windows dark and the target light. Confirm the target and `@thm_theme_name` are still light (the poller no longer reverts) and that the `system` file says dark.
- [ ] Tell the user: `exec fish` in open shells (the old `__terminal_theme_set` stays loaded until then). `~/.claude/themes/custom.json` is unmanaged and unused; delete it if wanted.
