# Chezmoi Test Architecture: Workflow-Mirroring Docker + Tiered Testing

Date: 2026-06-18

## Problem

The current Makefile and Dockerfile have split-brain: Makefile uses `--source-path` to name
individual scripts, so adding a new chezmoiscript requires updating both files or it silently
falls out of the test path. This is how `run_onchange_fish-universal` and `run_once_bat-symlink`
were never tested after being added.

Additionally, the Dockerfile never calls `chezmoi init` — it pre-copies a config and calls
`chezmoi apply` directly, bypassing config template rendering entirely. And `chezmoi.test.toml`
doubled as both a promptStringOnce seed and a package-list override, coupling two concerns.

## Goals

- Dockerfile mirrors the exact new-machine workflow (`chezmoi init --apply`)
- Adding a new chezmoiscript requires no Makefile or Dockerfile change
- Chezmoi's state DB is the sole cache/invalidation mechanism for what runs
- Tests are partitioned into tiers with distinct concerns and dependencies
- Docker build cache is preserved at meaningful phase boundaries

## Out of Scope

Script execution ordering (the alphabetical ordering bug where `fish-universal` runs before
`install-packages`). This design assumes that will be remedied separately, likely via numeric
prefixes on script filenames.

---

## Test Tiers

Three tiers, each with one concern:

| Tier | Question | Tool | Runs in |
|---|---|---|---|
| **Orchestration** | Does chezmoi's execution plan contain the right scripts in the right order? | `chezmoi apply --dry-run`, bash | Docker (any stage), CI, local |
| **Integration** | Did each phase produce the correct system state? | bash (`command -v`, `test -L`, `chezmoi state dump`) | Per Docker target |
| **Unit** | Do fish functions behave correctly? | fishtape | Local only |

**Orchestration** tests assert chezmoi's *plan* — not whether scripts succeed. They run
`chezmoi apply --dry-run` against a clean state and parse the output to verify script presence
and order. No fish, no package managers required.

**Integration** tests assert observable post-phase state: tools are reachable, symlinks exist,
universal vars are set, chezmoi state has the expected script hashes recorded. Written in bash,
no extra dependencies.

**Unit** tests assert fish function behavior (fisher sync, nudge hooks, completions). These
require fish to exist and are inappropriate for Docker's bootstrap phase. They stay local.

### Existing test file mapping

| File | Current tier | New tier |
|---|---|---|
| `tests/fish/fisher_chezmoi_test.fish` | cold install | Unit (local fishtape) |
| `tests/fish/fisher_cold_install_test.fish` | cold install | Integration (rewrite to bash) |
| `tests/fish/chezmoi_nudge_test.fish` | unit | Unit (local fishtape) |
| `tests/fish/git_extras_test.fish` | unit | Unit (local fishtape) |
| `tests/orchestration.sh` | — | Orchestration (new) |
| `tests/integration.sh` | — | Integration (new) |

---

## Dockerfile

Five stages, each a testable state. The Dockerfile IS the new-machine workflow.

```
package-managers-base
    FROM ubuntu:24.04
    apt: build-essential curl file gawk git procps
    mkdir /home/linuxbrew + chown testuser
    install chezmoi binary
    COPY .chezmoiroot
         home/.chezmoi.toml.tmpl
         home/.chezmoidata.toml
         home/.chezmoiscripts/run_onchange_bootstrap-package-managers.sh.tmpl
    COPY chezmoi.test.toml → ~/.config/chezmoi/chezmoi.toml
    RUN  chezmoi init --apply
         # renders config template (promptStringOnce reads pre-seeded values)
         # runs bootstrap: installs brew, rustup, cargo-binstall, uv
         # records bootstrap hash in state DB

packages
    FROM package-managers-base
    COPY home/.chezmoidata.toml
         home/.chezmoiscripts/run_onchange_install-packages.sh.tmpl
    RUN  chezmoi apply --include=scripts
         # bootstrap: state DB hit → skip
         # install-packages: runs, installs fish/bat/jj/etc.
         # records install-packages hash in state DB

post-install
    FROM packages
    COPY home/.chezmoiscripts/run_once_bat-symlink.sh.tmpl
         home/.chezmoiscripts/run_onchange_fish-universal.sh.tmpl
    RUN  chezmoi apply --include=scripts
         # bootstrap + install-packages: skip
         # bat-symlink + fish-universal: run (fish and bat now present)

dotfiles
    FROM post-install
    COPY . (full source)
    RUN  chezmoi apply --exclude=scripts

smoke
    FROM dotfiles
    CMD  make test-orchestration test-integration
```

### Docker cache invalidation

| Stage | Invalidated by |
|---|---|
| `package-managers-base` | bootstrap script changes, chezmoidata changes |
| `packages` | install-packages script changes, chezmoidata changes (package list) |
| `post-install` | bat-symlink or fish-universal script changes |
| `dotfiles` | any dotfile change |

The `packages` stage caches the expensive install layer (brew + cargo + uv). Dotfile-only
changes skip all four install stages and only rebuild `dotfiles`.

### chezmoi.test.toml

Shrinks to only the values that `promptStringOnce` needs — currently just `java_home`.
Package lists and fish_universal are no longer overridden here; they come from
`.chezmoidata.toml` in the source, which chezmoi picks up automatically.

```toml
[data]
  java_home = ""
```

---

## Makefile

Test runner only. No phase targets. No `--source-path`. No script names.

```makefile
SMOKE_IMAGE := chezmoi-smoke
SMOKE_SRC   := /home/testuser/.local/share/chezmoi

test-orchestration:
	bash tests/orchestration.sh

test-integration:
	bash tests/integration.sh

test-unit:
	fish -c 'fishtape tests/fish/chezmoi_nudge_test.fish \
	         tests/fish/fisher_chezmoi_test.fish \
	         tests/fish/git_extras_test.fish'

test-smoke:
	DOCKER_BUILDKIT=1 docker build --target smoke -t $(SMOKE_IMAGE) .
	docker run --rm $(SMOKE_IMAGE) make -C $(SMOKE_SRC) test-orchestration test-integration
```

Dev users run `chezmoi init --apply` or `chezmoi apply` directly — no Makefile needed
for dotfile management.

---

## New Test Files

### tests/orchestration.sh

Runs `chezmoi apply --dry-run` against a clean chezmoi state and asserts:
- All expected scripts appear in the output
- Scripts appear in correct order relative to each other
- No unexpected scripts are present

Does not require fish, brew, or any installed tools. Runs in `package-managers-base`
or earlier.

### tests/integration.sh

Per-phase bash assertions. Structured so each section can be targeted independently
by running against the appropriate Docker target:

- **After packages**: `command -v fish`, `command -v bat`, `command -v jj`, chezmoi
  state has bootstrap + install-packages hashes
- **After post-install**: `test -L ~/.local/bin/bat`, `fish -c 'echo $EDITOR'` = `hx`,
  `fish -c 'echo $BAT_THEME_DARK'` = `Dracula`
- **After dotfiles**: fisher plugins installed, chezmoiignore populated, config files
  deployed, user functions present

Replaces `tests/fish/fisher_cold_install_test.fish` for Docker use. The fish-specific
assertions from that file (function behavior, ignore sync logic) remain as unit tests.

---

## Migration Delta

| What changes | From | To |
|---|---|---|
| Makefile | phase targets + test targets, uses `--source-path` | test targets only, no chezmoi flags |
| Dockerfile | multi-stage with `make apply-*` calls | multi-stage with direct `chezmoi` calls |
| `chezmoi.test.toml` | package list overrides + java_home | java_home only |
| `tests/fish/fisher_cold_install_test.fish` | fishtape, runs in Docker | split: bash→integration.sh, fish→unit |
| `tests/orchestration.sh` | does not exist | new, bash |
| `tests/integration.sh` | does not exist | new, bash |
