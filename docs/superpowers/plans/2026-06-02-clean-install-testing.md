# Clean Install Testing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a three-tier test infrastructure (`make test-unit` / `make test` / `make test-smoke`) that verifies this chezmoi repo works on a clean Linux install, with CI running the fast suite and a local Docker smoke test covering the full bootstrap.

**Architecture:** Package consolidation eliminates the apt/snap install script and cargo packages section (everything moves to brew), leaving brew as the sole package manager for binaries. A new `Dockerfile.smoke` builds from `chezmoi-brew-base` with per-script COPY layers for BuildKit cache granularity. CI runs natively on Ubuntu, mirroring the fast-base Docker environment without Docker-in-Docker.

**Tech Stack:** GNU Make, Docker BuildKit, fishtape, GitHub Actions, chezmoi templates

---

## File Map

| Action | Path |
|---|---|
| Modify | `home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl` |
| Modify | `home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl` |
| Delete | `home/.chezmoiscripts/run_onchange_install-packages.sh.tmpl` |
| Create | `Makefile` |
| Modify | `mise.toml` |
| Create | `Dockerfile.smoke` |
| Create | `.github/workflows/test.yml` |
| Modify | `tests/fish/fisher_cold_install_test.fish` |

---

## Task 1: Expand brew package list

Move all packages from the deleted apt script and the cargo packages section into `install-brew.sh.tmpl`. Drop `pipx` (covered by `uv tool`).

**Files:**
- Modify: `home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl`

- [ ] **Replace the `$packages` list** in `run_onchange_install-brew.sh.tmpl`:

```
{{ $packages := list
  "xclip"
  "pcre2"
  "jj"
  "fish"
  "slides"
  "bat"
  "bat-extras-batman"
  "btop"
  "hurl"
  "fd"
  "fzf"
  "git"
  "helix"
  "ripgrep"
  "trash-cli"
  "tree"
  "marksman"
  "gh"
  "git-delta"
  "difftastic"
  "git-branchless"
  "git-cliff" -}}
```

- [ ] **Verify the template renders without error:**

```bash
chezmoi execute-template < home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl | head -40
```

Expected: script renders with all packages listed in the `brew install` lines, no template errors.

- [ ] **Commit:**

```bash
git add home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl
git commit -m "chore(chezmoi): consolidate all binary packages into brew"
```

---

## Task 2: Trim cargo script to plugins only

Remove the `$packages` list and its `range` block. Only plugins remain.

**Files:**
- Modify: `home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl`

- [ ] **Replace the full template** with the plugins-only version:

```
{{ $plugins := list
  "binstall"
  "expand"
  "hack"
  "llvm-cov"
  "nextest"
  "release"
  "shuttle"
  "spellcheck"
  "tauri" -}}

#!/usr/bin/bash
set -eufo pipefail

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -- -y --default-toolchain stable -- component cargo --component clippy

# install cargo-binstall
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

{{ range $plugins }}
  cargo binstall --locked cargo-{{ . }}
{{ end }}
```

- [ ] **Verify the template renders:**

```bash
chezmoi execute-template < home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl | head -20
```

Expected: script renders with only the `cargo binstall --locked cargo-<plugin>` lines, no package installs.

- [ ] **Commit:**

```bash
git add home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl
git commit -m "chore(chezmoi): move cargo packages to brew, keep plugins only"
```

---

## Task 3: Delete apt/snap install script

**Files:**
- Delete: `home/.chezmoiscripts/run_onchange_install-packages.sh.tmpl`

- [ ] **Delete the file:**

```bash
git rm home/.chezmoiscripts/run_onchange_install-packages.sh.tmpl
```

- [ ] **Commit:**

```bash
git commit -m "chore(chezmoi): remove apt/snap install script, packages moved to brew"
```

---

## Task 4: Create Makefile

**Files:**
- Create: `Makefile`

- [ ] **Create `Makefile`** at the repo root:

```makefile
.PHONY: test-unit test test-smoke

FISHTAPE    := fishtape
SMOKE_IMAGE := chezmoi-smoke

UNIT_TESTS := \
	tests/fish/chezmoi_nudge_test.fish \
	tests/fish/git_extras_test.fish

ALL_TESTS := \
	$(UNIT_TESTS) \
	tests/fish/fisher_chezmoi_test.fish \
	tests/fish/fisher_cold_install_test.fish

test-unit:
	$(FISHTAPE) $(UNIT_TESTS)

test:
	$(FISHTAPE) $(ALL_TESTS)

test-smoke:
	DOCKER_BUILDKIT=1 docker build --target brew-base -t chezmoi-brew-base .
	DOCKER_BUILDKIT=1 docker build -f Dockerfile.smoke -t $(SMOKE_IMAGE) .
	docker run --rm $(SMOKE_IMAGE) fish -c \
	    "jj --version && functions -q fisher && cargo nextest --version && uv tool list | grep -q py-spy"
```

- [ ] **Run unit tests to confirm wiring:**

```bash
make test-unit
```

Expected: fishtape output with passing tests for `chezmoi_nudge_test.fish` and `git_extras_test.fish`. All tests green.

- [ ] **Run integration tests to confirm wiring** (requires deployed dotfiles):

```bash
make test
```

Expected: fishtape output for all four suites. Tests pass (fisher-related tests require fisher to be installed locally).

- [ ] **Commit:**

```bash
git add Makefile
git commit -m "chore(chezmoi): add Makefile with test-unit, test, test-smoke targets"
```

---

## Task 5: Add mise task aliases

**Files:**
- Modify: `mise.toml`

- [ ] **Append task entries** to `mise.toml`:

```toml
[tasks.test-unit]
run = "make test-unit"

[tasks.test]
run = "make test"

[tasks.test-smoke]
run = "make test-smoke"
```

- [ ] **Verify mise picks up the tasks:**

```bash
mise tasks
```

Expected: `test-unit`, `test`, and `test-smoke` appear in the list.

- [ ] **Commit:**

```bash
git add mise.toml
git commit -m "chore(chezmoi): add mise task aliases for make test targets"
```

---

## Task 6: Create `Dockerfile.smoke`

Layer order maximises BuildKit cache: brew and cargo (slow) are above the full dotfile COPY so they survive dotfile-only changes. Fisher runs after `chezmoi apply --exclude scripts` because it needs `fisher_chezmoi_sync.fish` deployed.

**Files:**
- Create: `Dockerfile.smoke`

- [ ] **Create `Dockerfile.smoke`** at the repo root:

```dockerfile
ARG DEBIAN_FRONTEND=noninteractive

FROM chezmoi-brew-base AS smoke

# Brew packages (includes fish) — slow layer, cached until script changes
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi execute-template \
      < /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl \
      | bash

# Cargo plugins only — slow layer, cached until script changes
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi execute-template \
      < /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl \
      | bash

# UV tools — moderate speed, cached until script changes
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_onchange_install-uv.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi execute-template \
      < /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-uv.sh.tmpl \
      | bash

# Full dotfiles — invalidates fisher layer below on any dotfile change
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/
RUN chezmoi apply --exclude scripts

# Fisher install — must follow chezmoi apply (needs fisher_chezmoi_sync.fish deployed)
RUN chezmoi execute-template \
      < /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-fish.fish.tmpl \
      | /home/testuser/.homebrew/bin/fish

CMD ["/home/testuser/.homebrew/bin/fish"]
```

- [ ] **Build `brew-base` then the smoke image:**

```bash
DOCKER_BUILDKIT=1 docker build --target brew-base -t chezmoi-brew-base .
DOCKER_BUILDKIT=1 docker build -f Dockerfile.smoke -t chezmoi-smoke .
```

Expected: both builds complete without error. Brew-base is slow on first run; subsequent runs reuse the cache.

- [ ] **Run spot-checks manually:**

```bash
docker run --rm chezmoi-smoke fish -c \
    "jj --version && functions -q fisher && cargo nextest --version && uv tool list | grep -q py-spy && echo ALL_CHECKS_PASSED"
```

Expected: output ends with `ALL_CHECKS_PASSED`.

- [ ] **Commit:**

```bash
git add Dockerfile.smoke
git commit -m "chore(chezmoi): add Dockerfile.smoke for full bootstrap smoke test"
```

---

## Task 7: Verify `make test-smoke` end-to-end

- [ ] **Run the full smoke target:**

```bash
make test-smoke
```

Expected: builds brew-base (cached after Task 6), builds smoke image, runs spot-checks, exits 0.

- [ ] **Confirm cache works** — touch a fish config file and re-run:

```bash
touch home/private_dot_config/private_fish/aliases.fish
make test-smoke
```

Expected: brew and cargo layers reuse cache (Docker output shows `CACHED`), only the dotfile COPY + apply + fisher layers rebuild.

---

## Task 8: Add GitHub Actions CI workflow

**Files:**
- Create: `.github/workflows/test.yml`

- [ ] **Create the workflow file:**

```bash
mkdir -p .github/workflows
```

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
        run: |
          chezmoi execute-template \
            < home/.chezmoiscripts/run_onchange_install-fish.fish.tmpl \
            | fish

      - name: Install fishtape
        run: fish -c 'fisher install jorgebucaran/fishtape'

      - name: Run tests
        run: make test
```

- [ ] **Commit and push to trigger CI:**

```bash
git add .github/workflows/test.yml
git commit -m "ci: add GitHub Actions workflow for fast test suite"
git push
```

- [ ] **Verify CI passes** in the GitHub Actions tab. All four fishtape suites should be green.

---

## Task 9: Update `fisher_cold_install_test.fish` header comment

The test no longer requires a Docker integration image — it runs anywhere chezmoi apply + fisher install has been done.

**Files:**
- Modify: `tests/fish/fisher_cold_install_test.fish`

- [ ] **Replace the header comment block** (lines 1–4):

Old:
```fish
#!/usr/bin/env fish
# Cold install integration tests — run against the integration image only
# Requires: docker build -f Dockerfile.integration -t chezmoi-integration .
# Run: fishtape tests/fish/fisher_cold_install_test.fish
```

New:
```fish
#!/usr/bin/env fish
# Cold install integration tests — requires chezmoi apply + fisher install done
# Run locally: make test
# Run in CI: make test (GitHub Actions handles setup)
```

- [ ] **Run tests one final time to confirm nothing broke:**

```bash
make test-unit
make test
```

Expected: all tests pass.

- [ ] **Commit:**

```bash
git add tests/fish/fisher_cold_install_test.fish
git commit -m "docs(test): update fisher cold install test header — no longer Docker-only"
```
