# Clean Install Testing Design

## Goal

Simulate bootstrapping this chezmoi repo on a fresh Linux instance, with a fast feedback loop for development and a full smoke test for verifying the end-to-end install path.

## Tier Structure

Three tiers, two make targets used in CI, one local-only:

```
make test-unit    Tier 1 — unit fishtape tests, no environment setup
make test         Tier 1+2 — all fishtape tests, requires deployed dotfiles
make test-smoke   Tier 3 — full cold install in Docker, local only
```

CI runs `make test`. The CI environment (Ubuntu + apt fish + chezmoi apply) is treated as equivalent to the `fast-base` Docker target — no Docker-in-Docker needed.

## Tier 1: Unit Tests (`make test-unit`)

Runs `chezmoi_nudge_test.fish` and `git_extras_test.fish`. These source files directly from the repo root — no chezmoi apply, no deployed environment. Fast enough for tight feedback during hook or completion development.

## Tier 2: Integration Tests (`make test`)

Runs all four fishtape suites. Requires:
- `chezmoi apply` completed (dotfiles deployed)
- Fisher install script executed (fisher + plugins present)

CI satisfies this by installing fish via apt, installing chezmoi, running `chezmoi apply --exclude scripts`, then executing `run_onchange_install-fish.fish.tmpl` before `make test`.

`fisher_cold_install_test.fish` (currently documented as Docker-only) runs here — its assertions (fisher tracks plugins, chezmoiignore populated, chezmoi add skips fisher files, user files intact) hold in any environment where chezmoi apply + fisher install has been done.

## Tier 3: Smoke Test (`make test-smoke`)

Local only. Builds `Dockerfile.smoke`, then runs spot-checks inside the resulting container.

### `Dockerfile.smoke` structure

`Dockerfile.smoke` uses `FROM chezmoi-brew-base` — it depends on the `brew-base` target from the existing `Dockerfile` being built first (`make test-smoke` builds brew-base then smoke). This avoids duplicating the brew bootstrap and shares the BuildKit layer cache. Each install script is then COPYed individually just before its `RUN` step so changing one script only invalidates that layer and below.

```
brew-base
  COPY install-brew.sh.tmpl    →  RUN (brew packages incl. fish)   [slow, cached]
  COPY install-fish.fish.tmpl  →  RUN (fisher + plugins)           [depends on brew fish]
  COPY install-cargo.sh.tmpl   →  RUN (cargo plugins only)         [slow, cached]
  COPY install-uv.sh.tmpl      →  RUN (uv tools)                   [moderate, cached]
  COPY . (full dotfiles)       →  RUN chezmoi apply
```

No sudo required — apt is not used in the smoke container.

### Spot-checks (one per package manager)

| Manager | Check | Why this package |
|---|---|---|
| brew | `jj --version` | brew-only, not in apt/cargo |
| fisher | `fish -c 'functions -q fisher'` | presence of fisher function |
| cargo | `cargo nextest --version` | representative plugin |
| uv | `uv tool list \| grep py-spy` | representative uv tool |

## Package Consolidation

A prerequisite to the smoke Dockerfile: consolidate packages so apt and snap are eliminated.

**`run_onchange_install-packages.sh.tmpl` → deleted.** All packages move to brew:

| Was apt | Was snap | Brew formula |
|---|---|---|
| bat, btop, fzf, ripgrep, tree, trash-cli | | same name |
| fd-find | | `fd` |
| helix (via PPA) | | `helix` (eliminates PPA) |
| pipx | | dropped — `uv tool` covers it |
| | marksman | `marksman` |
| gh (custom apt) | | `gh` |
| | docker | out of scope |

**`run_onchange_install-cargo.sh.tmpl` — packages section removed.** These move to brew:

| Was cargo binstall | Brew formula |
|---|---|
| delta | `git-delta` |
| difft | `difftastic` |
| git-branchless | `git-branchless` |
| git-cliff | `git-cliff` |

The cargo plugins (`nextest`, `llvm-cov`, `expand`, `hack`, `release`, `shuttle`, `spellcheck`, `tauri`, `binstall`) have no brew alternative and remain.

## Makefile

```makefile
.PHONY: test-unit test test-smoke

FISHTAPE := fishtape
UNIT_TESTS  := tests/fish/chezmoi_nudge_test.fish \
               tests/fish/git_extras_test.fish
ALL_TESTS   := $(UNIT_TESTS) \
               tests/fish/fisher_chezmoi_test.fish \
               tests/fish/fisher_cold_install_test.fish
SMOKE_IMAGE := chezmoi-smoke

test-unit:
	$(FISHTAPE) $(UNIT_TESTS)

test:
	$(FISHTAPE) $(ALL_TESTS)

test-smoke:
	DOCKER_BUILDKIT=1 docker build -f Dockerfile.smoke -t $(SMOKE_IMAGE) .
	docker run --rm $(SMOKE_IMAGE) fish -c " \
	    jj --version && \
	    functions -q fisher && \
	    cargo nextest --version && \
	    uv tool list | grep py-spy"
```

## Mise Aliases

Added to `mise.toml` for local DX only — CI uses `make` directly:

```toml
[tasks.test-unit]
run = "make test-unit"

[tasks.test]
run = "make test"

[tasks.test-smoke]
run = "make test-smoke"
```

## CI (GitHub Actions)

`.github/workflows/test.yml` — runs on push and pull_request:

```yaml
name: test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install fish + chezmoi
        run: |
          sudo apt-get update && sudo apt-get install -y fish
          sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
          echo "$HOME/.local/bin" >> $GITHUB_PATH
      - name: Apply dotfiles
        run: chezmoi init --apply --source=$GITHUB_WORKSPACE
      - name: Install fisher + plugins
        run: chezmoi execute-template \
               < home/.chezmoiscripts/run_onchange_install-fish.fish.tmpl \
               | fish
      - name: Install fishtape
        run: fish -c 'fisher install jorgebucaran/fishtape'
      - name: Run tests
        run: make test
```

## Testing Strategy

- `make test-unit` — run during active development of a fish hook or completion file
- `make test` — run before committing; also the CI gate
- `make test-smoke` — run before merging changes to install scripts or the Dockerfile
