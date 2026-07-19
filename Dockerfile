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
# Re-COPY forces cache invalidation when package list changes independently of bootstrap
COPY --chown=testuser:testuser home/.chezmoidata.toml \
    /home/testuser/.local/share/chezmoi/home/.chezmoidata.toml
COPY --chown=testuser:testuser \
    home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl \
    /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
# install-packages template includes fish_plugins for hash tracking
COPY --chown=testuser:testuser \
    home/private_dot_config/private_fish/fish_plugins \
    /home/testuser/.local/share/chezmoi/home/private_dot_config/private_fish/fish_plugins

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
# Deploys all managed files, then runs any run_onchange_after_ scripts that
# depend on those files already being in place (e.g. terminal-theme-timer,
# which enables a systemd unit only after it has been deployed). 01-04 are
# already recorded in state from earlier stages and are skipped as unchanged;
# only run_onchange_after_05-terminal-theme-timer actually executes here.
# Invalidated by: any dotfile change.

FROM post-install AS dotfiles
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/
RUN chezmoi apply --exclude=scripts
RUN chezmoi apply --include=scripts

# ── smoke ─────────────────────────────────────────────────────────────────────
# Test runner: orchestration + integration tiers.

FROM dotfiles AS smoke
WORKDIR /home/testuser/.local/share/chezmoi
CMD ["make", "test-orchestration", "test-integration"]
