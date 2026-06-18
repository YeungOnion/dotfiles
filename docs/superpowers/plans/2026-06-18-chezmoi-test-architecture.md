# Chezmoi Test Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the split-brain Makefile+Dockerfile test setup with a Dockerfile that mirrors the exact new-machine `chezmoi init --apply` workflow and a Makefile that is a pure test runner.

**Architecture:** Five Dockerfile stages (package-managers-base, packages, post-install, dotfiles, smoke) each call `chezmoi` directly in workflow order; chezmoi's state DB prevents re-running scripts across stages. Tests are split into three tiers: orchestration (bash + chezmoi dry-run), integration (bash assertions on system state), and unit (fishtape, local only).

**Tech Stack:** bash, chezmoi, Docker BuildKit, fishtape (unit tier only), jq

## Global Constraints

- No `--source-path` flag anywhere in Makefile or Dockerfile
- No script filenames in Makefile or Dockerfile (adding a new script must not require changes to either file)
- Dockerfile stages must call `chezmoi` directly — no `make apply-*` delegation
- `tests/orchestration.sh` and `tests/integration.sh` must be plain bash with no extra runtime deps
- Script ordering is enforced by numeric prefixes (`01-`, `02-`, `03-`, `04-`) — do not reorder by renaming
- Current script names (as of this plan): `run_onchange_01-bootstrap-package-managers.sh.tmpl`, `run_onchange_02-install-packages.sh.tmpl`, `run_onchange_03-bat-symlink.sh.tmpl`, `run_onchange_04-fish-universal.sh.tmpl`

---

### Task 1: Write tests/orchestration.sh

**Files:**
- Create: `tests/orchestration.sh`

**Interfaces:**
- Produces: exits 0 on pass, 1 on any failure; prints `ok:` / `FAIL:` lines to stdout

- [ ] **Step 1: Create tests/orchestration.sh**

```bash
#!/bin/bash
# Orchestration test: verify chezmoi's execution plan contains all scripts in correct order.
# Clears scriptState to get the full plan, asserts order, then chezmoi apply restores state.
set -uo pipefail

SCRIPTS=(
    "01-bootstrap-package-managers"
    "02-install-packages"
    "03-bat-symlink"
    "04-fish-universal"
)

fail=0
ok()   { echo "ok: $*"; }
fail() { echo "FAIL: $*"; fail=1; }

# Clear script state so dry-run shows the full plan
chezmoi state delete-bucket scriptState 2>/dev/null || true

# Capture the plan; chezmoi apply --dry-run --verbose emits diff --git lines per script
plan=$(chezmoi apply --dry-run --verbose 2>&1)

# Restore state so subsequent chezmoi apply calls behave normally
chezmoi apply --quiet 2>/dev/null || true

# Assert each expected script appears in the plan
for script in "${SCRIPTS[@]}"; do
    if echo "$plan" | grep -qF ".chezmoiscripts/${script}.sh"; then
        ok "$script present in plan"
    else
        fail "$script missing from plan"
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
        fail "$prev not before $curr (lines: ${line_prev:-missing} vs ${line_curr:-missing})"
    fi
done

# Assert no unexpected scripts appear (catches stray scripts without numeric prefix)
unexpected=$(echo "$plan" | grep -oP '(?<=\.chezmoiscripts/)[^.]+(?=\.sh)' \
    | grep -vE "^(01-bootstrap-package-managers|02-install-packages|03-bat-symlink|04-fish-universal)$" \
    || true)
if [[ -z "$unexpected" ]]; then
    ok "no unexpected scripts in plan"
else
    fail "unexpected scripts in plan: $unexpected"
fi

exit $fail
```

- [ ] **Step 2: Make executable**

```bash
chmod +x tests/orchestration.sh
```

- [ ] **Step 3: Run locally and verify it passes**

```bash
bash tests/orchestration.sh
```

Expected output:
```
ok: 01-bootstrap-package-managers present in plan
ok: 02-install-packages present in plan
ok: 03-bat-symlink present in plan
ok: 04-fish-universal present in plan
ok: 01-bootstrap-package-managers before 02-install-packages
ok: 02-install-packages before 03-bat-symlink
ok: 03-bat-symlink before 04-fish-universal
ok: no unexpected scripts in plan
```

- [ ] **Step 4: Commit**

```bash
git add tests/orchestration.sh
git commit -m "test(orchestration): assert chezmoi script plan order via dry-run"
```

---

### Task 2: Write tests/integration.sh

**Files:**
- Create: `tests/integration.sh`

**Interfaces:**
- Produces: exits 0 on pass, 1 on any failure; prints `ok:` / `FAIL:` lines to stdout

- [ ] **Step 1: Create tests/integration.sh**

```bash
#!/bin/bash
# Integration test: verify system state after each chezmoi init phase.
# Runs in the smoke Docker target (all phases complete) but assertions are
# grouped by the phase that produces each state, for documentation clarity.
set -uo pipefail

fail=0
ok()     { echo "ok: $*"; }
check_fail() { echo "FAIL: $*"; fail=1; }

# ── after packages phase ──────────────────────────────────────────────────────

echo "# packages phase"

for tool in fish bat jj cargo uv; do
    if command -v "$tool" &>/dev/null; then
        ok "$tool in PATH"
    else
        check_fail "$tool not in PATH"
    fi
done

# chezmoi state must record both bootstrap and install-packages
for script in "01-bootstrap-package-managers" "02-install-packages"; do
    if chezmoi state dump 2>/dev/null \
            | jq -e --arg s "$script" \
              '.scriptState // {} | to_entries[].value.name | select(contains($s))' \
            &>/dev/null; then
        ok "$script recorded in chezmoi state"
    else
        check_fail "$script not recorded in chezmoi state"
    fi
done

# ── after post-install phase ──────────────────────────────────────────────────

echo "# post-install phase"

if [[ $(uname) == "Linux" ]]; then
    if [[ -L "$HOME/.local/bin/bat" ]]; then
        ok "~/.local/bin/bat is a symlink"
    else
        check_fail "~/.local/bin/bat is not a symlink"
    fi
fi

editor=$(fish -c 'echo $EDITOR' 2>/dev/null)
if [[ "$editor" == "hx" ]]; then
    ok "EDITOR universal var is hx"
else
    check_fail "EDITOR universal var is '${editor}' (expected hx)"
fi

bat_dark=$(fish -c 'echo $BAT_THEME_DARK' 2>/dev/null)
if [[ "$bat_dark" == "Dracula" ]]; then
    ok "BAT_THEME_DARK universal var is Dracula"
else
    check_fail "BAT_THEME_DARK universal var is '${bat_dark}' (expected Dracula)"
fi

# ── after dotfiles phase ──────────────────────────────────────────────────────

echo "# dotfiles phase"

for f in \
    "$HOME/.config/fish/aliases.fish" \
    "$HOME/.config/fish/config.fish" \
    "$HOME/.config/fish/fish_plugins" \
    "$HOME/.config/fish/conf.d/fisher_chezmoi_sync.fish"; do
    if [[ -f "$f" ]]; then
        ok "${f/$HOME/~} deployed"
    else
        check_fail "${f/$HOME/~} not deployed"
    fi
done

# fish must start without stderr
stderr=$(fish -c exit 2>&1)
if [[ -z "$stderr" ]]; then
    ok "fish starts without stderr"
else
    check_fail "fish starts with stderr: $stderr"
fi

# chezmoiignore must have fisher block
chezmoi_src=$(chezmoi source-path 2>/dev/null)
chezmoiignore="$chezmoi_src/.chezmoiignore"
if grep -qF '# fisher:begin' "$chezmoiignore" 2>/dev/null; then
    ok "fisher:begin block in .chezmoiignore"
else
    check_fail "fisher:begin block missing from .chezmoiignore"
fi

if awk '/^# fisher:begin/{p=1;next} /^# fisher:end/{p=0} p && NF' \
        "$chezmoiignore" 2>/dev/null | grep -q .; then
    ok "fisher ignore block is non-empty"
else
    check_fail "fisher ignore block is empty"
fi

# user-managed function must not appear in fisher ignore block
if awk '/^# fisher:begin/{p=1;next} /^# fisher:end/{p=0} p' "$chezmoiignore" \
        | grep -qF '__append_pipe_fzf.fish'; then
    check_fail "__append_pipe_fzf.fish incorrectly in fisher ignore block"
else
    ok "__append_pipe_fzf.fish not in fisher ignore block"
fi

exit $fail
```

- [ ] **Step 2: Make executable**

```bash
chmod +x tests/integration.sh
```

- [ ] **Step 3: Run locally and verify it passes**

```bash
bash tests/integration.sh
```

Expected: all `ok:` lines, exit 0. (The `jq` assertions for chezmoi state require `jq` installed locally; if missing, install via `brew install jq`.)

- [ ] **Step 4: Commit**

```bash
git add tests/integration.sh
git commit -m "test(integration): bash assertions for all post-phase system state"
```

---

### Task 3: Slim chezmoi.test.toml to promptStringOnce values only

**Files:**
- Modify: `chezmoi.test.toml`

**Interfaces:**
- Consumed by: Dockerfile (copied to `~/.config/chezmoi/chezmoi.toml` before `chezmoi init --apply`)
- Produces: a pre-seeded config that makes `promptStringOnce . "java_home" "..."` return `""` without prompting

- [ ] **Step 1: Replace chezmoi.test.toml**

```toml
[data]
  java_home = ""
```

- [ ] **Step 2: Verify chezmoi can still apply with the new config**

```bash
chezmoi apply --config /dev/stdin <<'EOF'
[data]
  java_home = ""
EOF
```

Expected: applies without error (dotfiles and scripts behave normally; `.chezmoidata.toml` in the source provides all package lists and fish_universal).

- [ ] **Step 3: Commit**

```bash
git add chezmoi.test.toml
git commit -m "chore(test): slim chezmoi.test.toml to promptStringOnce seed only"
```

---

### Task 4: Rewrite Makefile as test-only runner

**Files:**
- Modify: `Makefile`

**Interfaces:**
- `test-orchestration`: runs `tests/orchestration.sh` via bash
- `test-integration`: runs `tests/integration.sh` via bash
- `test-unit`: runs unit fishtape tests locally
- `test-smoke`: builds and runs the smoke Docker target

- [ ] **Step 1: Replace Makefile entirely**

```makefile
.PHONY: test-orchestration test-integration test-unit test-smoke

SMOKE_IMAGE := chezmoi-smoke
SMOKE_SRC   := /home/testuser/.local/share/chezmoi

test-orchestration:
	bash tests/orchestration.sh

test-integration:
	bash tests/integration.sh

test-unit:
	fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish \
	         tests/fish/fisher_chezmoi_test.fish \
	         tests/fish/fisher_cold_install_test.fish \
	         tests/fish/git_extras_test.fish'

test-smoke:
	DOCKER_BUILDKIT=1 docker build --target smoke -t $(SMOKE_IMAGE) .
	docker run --rm $(SMOKE_IMAGE) make -C $(SMOKE_SRC) test-orchestration test-integration
```

- [ ] **Step 2: Verify test-unit still passes locally**

```bash
make test-unit
```

Expected: all fishtape tests pass (21 ok).

- [ ] **Step 3: Verify test-orchestration and test-integration pass locally**

```bash
make test-orchestration
make test-integration
```

Expected: both exit 0.

- [ ] **Step 4: Commit**

```bash
git add Makefile
git commit -m "refactor(make): Makefile is now test-only, no phase targets or --source-path"
```

---

### Task 5: Rewrite Dockerfile to mirror the new-machine workflow

**Files:**
- Modify: `Dockerfile`

**Interfaces:**
- Stage `package-managers-base`: installs brew/rustup/cargo-binstall/uv via `chezmoi init --apply`; chezmoi state records bootstrap hash
- Stage `packages`: installs all tools via `chezmoi apply --include=scripts`; chezmoi state skips bootstrap, records install-packages hash
- Stage `post-install`: runs bat-symlink + fish-universal via `chezmoi apply --include=scripts`
- Stage `dotfiles`: deploys all managed files via `chezmoi apply --exclude=scripts`
- Stage `smoke`: runs `make test-orchestration test-integration` as CMD

- [ ] **Step 1: Replace Dockerfile entirely**

```dockerfile
ARG DEBIAN_FRONTEND=noninteractive

# ── package-managers-base ─────────────────────────────────────────────────────
# Runs chezmoi init --apply with only the bootstrap script present.
# chezmoi renders .chezmoi.toml.tmpl (promptStringOnce reads pre-seeded config)
# then runs bootstrap: installs brew, rustup, cargo-binstall, uv.
# Records bootstrap hash in chezmoi state DB.
# Invalidated by: bootstrap script or .chezmoidata.toml changes.

FROM ubuntu:24.04 AS package-managers-base
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y \
    build-essential curl file gawk git jq procps \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash testuser
# Standard linuxbrew prefix — bottles are built for this path
RUN mkdir -p /home/linuxbrew && chown testuser:testuser /home/linuxbrew
USER testuser
WORKDIR /home/testuser
ENV HOME=/home/testuser
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/.local/bin
ENV PATH="/home/testuser/.local/bin:${PATH}"

# Pre-seed config so promptStringOnce does not block on stdin
RUN mkdir -p /home/testuser/.config/chezmoi
COPY --chown=testuser:testuser chezmoi.test.toml /home/testuser/.config/chezmoi/chezmoi.toml

# Minimal source for bootstrap: root marker, config template, data, bootstrap script
COPY --chown=testuser:testuser .chezmoiroot \
    /home/testuser/.local/share/chezmoi/.chezmoiroot
COPY --chown=testuser:testuser home/.chezmoi.toml.tmpl \
    /home/testuser/.local/share/chezmoi/home/.chezmoi.toml.tmpl
COPY --chown=testuser:testuser home/.chezmoidata.toml \
    /home/testuser/.local/share/chezmoi/home/.chezmoidata.toml
COPY --chown=testuser:testuser \
    home/.chezmoiscripts/run_onchange_01-bootstrap-package-managers.sh.tmpl \
    /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/

RUN chezmoi init --apply

ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/testuser/.cargo/bin:${PATH}"

# ── packages ──────────────────────────────────────────────────────────────────
# chezmoi apply sees bootstrap (already in state DB → skip) and
# install-packages (new → runs): installs fish, bat, jj, and all other tools.
# Invalidated by: install-packages script or .chezmoidata.toml changes.

FROM package-managers-base AS packages
COPY --chown=testuser:testuser home/.chezmoidata.toml \
    /home/testuser/.local/share/chezmoi/home/.chezmoidata.toml
COPY --chown=testuser:testuser \
    home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl \
    /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/

RUN chezmoi apply --include=scripts

# ── post-install ──────────────────────────────────────────────────────────────
# Runs bat-symlink and fish-universal now that fish and bat are available.
# Invalidated by: bat-symlink or fish-universal script changes.

FROM packages AS post-install
COPY --chown=testuser:testuser \
    home/.chezmoiscripts/run_onchange_03-bat-symlink.sh.tmpl \
    home/.chezmoiscripts/run_onchange_04-fish-universal.sh.tmpl \
    /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/

RUN chezmoi apply --include=scripts

# ── dotfiles ──────────────────────────────────────────────────────────────────
# Deploys all managed files. Scripts are excluded (all already ran above).
# Invalidated by: any dotfile change.

FROM post-install AS dotfiles
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/
RUN chezmoi apply --exclude=scripts

# ── smoke ─────────────────────────────────────────────────────────────────────
# Test runner: orchestration + integration tiers.

FROM dotfiles AS smoke
WORKDIR /home/testuser/.local/share/chezmoi
CMD ["make", "test-orchestration", "test-integration"]
```

- [ ] **Step 2: Build just the packages stage to verify it compiles (fast check before full build)**

```bash
DOCKER_BUILDKIT=1 docker build --target packages -t chezmoi-packages-check .
```

Expected: builds successfully. This stage is the slow one (~10 min on first run, cached thereafter).

- [ ] **Step 3: Run the full smoke test**

```bash
make test-smoke
```

Expected:
```
ok: 01-bootstrap-package-managers present in plan
ok: 02-install-packages present in plan
ok: 03-bat-symlink present in plan
ok: 04-fish-universal present in plan
ok: 01-bootstrap-package-managers before 02-install-packages
...
ok: no unexpected scripts in plan
# packages phase
ok: fish in PATH
ok: bat in PATH
ok: jj in PATH
...
# post-install phase
ok: ~/.local/bin/bat is a symlink
ok: EDITOR universal var is hx
ok: BAT_THEME_DARK universal var is Dracula
# dotfiles phase
ok: ~/.config/fish/aliases.fish deployed
...
```

- [ ] **Step 4: Commit**

```bash
git add Dockerfile
git commit -m "refactor(docker): workflow-mirroring stages with direct chezmoi commands, no make delegation"
```

---

### Task 6: Trim fisher_cold_install_test.fish to unit-tier concerns

**Files:**
- Modify: `tests/fish/fisher_cold_install_test.fish`

The assertions that moved to `tests/integration.sh` (shell health, file deployment, universal vars, bat symlink, chezmoiignore file checks) must be removed from this file. What remains are the fisher-specific behavioral tests that require fisher internals and can only run in fish.

- [ ] **Step 1: Replace the file content**

```fish
#!/usr/bin/env fish
# Unit tests for cold-install fisher state — requires fisher install done.
# Run locally: make test-unit

set -g _chezmoi_src (chezmoi source-path 2>/dev/null)
set -g _chezmoiignore $_chezmoi_src/.chezmoiignore

source ~/.config/fish/conf.d/fisher_chezmoi_sync.fish 2>/dev/null

# ── all plugins from fish_plugins are installed ───────────────────────────────

@echo "fisher plugins installed"

set -l plugins (cat ~/.config/fish/fish_plugins | string trim | grep -v '^$')

for plugin in $plugins
    @test "$plugin: fisher tracks it" \
        (set -q _fisher_plugins && string match -q "*$plugin*" $_fisher_plugins && echo yes || echo no) = yes
end

# ── chezmoi add does not pick up fisher files ─────────────────────────────────

@echo "chezmoi add excludes fisher-managed files"

set -l before (chezmoi managed ~/.config/fish/functions 2>/dev/null | sort)
chezmoi add ~/.config/fish/functions 2>/dev/null
set -l after (chezmoi managed ~/.config/fish/functions 2>/dev/null | sort)

@test "__z.fish not added to chezmoi source" \
    (contains -- .config/fish/functions/__z.fish $after && echo yes || echo no) = no
```

- [ ] **Step 2: Verify test-unit passes locally**

```bash
make test-unit
```

Expected: all fishtape tests pass (fewer assertions than before, all green).

- [ ] **Step 3: Commit**

```bash
git add tests/fish/fisher_cold_install_test.fish
git commit -m "refactor(test): trim cold install fish tests to unit-tier concerns only"
```

---

## Self-Review

**Spec coverage:**
- Dockerfile mirrors new-machine workflow (`chezmoi init --apply`) ✓ Task 5
- Adding a new script requires no Makefile/Dockerfile change ✓ Tasks 4+5 (no script names anywhere)
- Chezmoi state DB is sole cache mechanism ✓ Task 5 (each stage calls `chezmoi apply`, state handles skipping)
- Tests partitioned into tiers ✓ Tasks 1+2+6 (orchestration/integration/unit)
- Docker build cache at meaningful phase boundaries ✓ Task 5 (5 stages, each invalidated independently)
- `chezmoi.test.toml` shrinks to `java_home` only ✓ Task 3
- `tests/orchestration.sh` asserts dry-run plan ✓ Task 1
- `tests/integration.sh` asserts post-phase state ✓ Task 2
- `fisher_cold_install_test.fish` trimmed to unit concerns ✓ Task 6
- Migration delta (Makefile, Dockerfile, test files) ✓ Tasks 3-6

**Type consistency:** No shared function names across tasks; bash scripts use consistent `ok`/`check_fail` pattern in both test files.

**Placeholder scan:** No TBDs, no "implement later", no "handle edge cases". All commands are exact.

**One implementation note:** `chezmoi init --apply` (no repo arg) requires that the source dir already exists at the default location. The Dockerfile ensures this via the preceding `COPY` instructions. If `chezmoi init` requires a repo argument in the installed version, substitute `chezmoi apply --init` (which explicitly recreates the config from template before applying).
