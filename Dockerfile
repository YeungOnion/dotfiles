ARG DEBIAN_FRONTEND=noninteractive

# ── fast path (apt fish, no brew) ─────────────────────────────────────────────
# Targets: fast-base (chezmoi-test), integration (chezmoi-integration)

FROM ubuntu:24.04 AS fast-base
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y curl fish gawk git \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /usr/bin/fish testuser
USER testuser
WORKDIR /home/testuser
ENV HOME=/home/testuser
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/.local/bin
ENV PATH="/home/testuser/.local/bin:${PATH}"
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/
RUN chezmoi apply --exclude scripts
CMD ["fish"]

FROM fast-base AS integration
RUN chezmoi apply --include=scripts --source-path \
      /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-fish.fish.tmpl
CMD ["fish"]

# ── full bootstrap (brew fish, cold install) ──────────────────────────────────
# Targets: package-managers-base (chezmoi-package-managers-base), bootstrap (chezmoi-bootstrap)

FROM ubuntu:24.04 AS package-managers-base
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y \
    build-essential curl file gawk git procps \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash testuser
# Standard linuxbrew prefix — bottles are built for this path, avoids source compilation
RUN mkdir -p /home/linuxbrew && chown testuser:testuser /home/linuxbrew
USER testuser
WORKDIR /home/testuser
ENV HOME=/home/testuser
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/.local/bin
ENV PATH="/home/testuser/.local/bin:${PATH}"
# Copy source root marker + bootstrap script — isolates this slow layer from dotfile changes
COPY --chown=testuser:testuser \
     .chezmoiroot \
     /home/testuser/.local/share/chezmoi/.chezmoiroot
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_onchange_bootstrap-package-managers.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi apply --include=scripts --source-path \
      /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_bootstrap-package-managers.sh.tmpl
ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
ENV HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/testuser/.cargo/bin:${PATH}"
RUN brew update --force --quiet
RUN curl https://mise.run | sh

FROM package-managers-base AS smoke
# Config — test package set (minimal, matches smoke assertions)
COPY --chown=testuser:testuser chezmoi.test.toml /home/testuser/.config/chezmoi/chezmoi.toml
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/
WORKDIR /home/testuser/.local/share/chezmoi
RUN make apply-dotfiles
RUN make apply-packages
CMD ["/home/linuxbrew/.linuxbrew/bin/fish"]

FROM package-managers-base AS bootstrap
COPY --chown=testuser:testuser home/.chezmoi.toml.tmpl /home/testuser/.config/chezmoi/chezmoi.toml
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi apply --include=scripts --source-path \
      /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-brew.sh.tmpl
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi apply --include=scripts --source-path \
      /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-cargo.sh.tmpl
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_onchange_install-uv.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi apply --include=scripts --source-path \
      /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-uv.sh.tmpl
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/
RUN chezmoi apply --exclude scripts
RUN chezmoi apply --include=scripts --source-path \
      /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-fish.fish.tmpl
CMD ["/home/linuxbrew/.linuxbrew/bin/fish"]
