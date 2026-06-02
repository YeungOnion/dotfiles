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
RUN chezmoi execute-template \
      < /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-fish.fish.tmpl \
      | fish
CMD ["fish"]

# ── full bootstrap (brew fish, cold install) ──────────────────────────────────
# Targets: brew-base (chezmoi-brew-base), bootstrap (chezmoi-bootstrap)

FROM ubuntu:24.04 AS brew-base
ARG DEBIAN_FRONTEND
RUN apt-get update && apt-get install -y \
    build-essential curl file gawk git procps \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash testuser
USER testuser
WORKDIR /home/testuser
ENV HOME=/home/testuser
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/.local/bin
ENV PATH="/home/testuser/.local/bin:${PATH}"
# Copy only the brew script — isolates this slow layer from dotfile changes
COPY --chown=testuser:testuser \
     home/.chezmoiscripts/run_install-brew.sh.tmpl \
     /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/
RUN chezmoi execute-template \
      < /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_install-brew.sh.tmpl \
      | bash
ENV HOMEBREW_PREFIX="/home/testuser/.homebrew"
ENV HOMEBREW_CELLAR="/home/testuser/.homebrew/Cellar"
ENV HOMEBREW_REPOSITORY="/home/testuser/.homebrew"
ENV PATH="/home/testuser/.homebrew/bin:/home/testuser/.homebrew/sbin:${PATH}"
RUN brew update --force --quiet
RUN curl https://mise.run | sh

FROM brew-base AS bootstrap
COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/
RUN chezmoi apply --exclude scripts
RUN chezmoi execute-template \
      < /home/testuser/.local/share/chezmoi/home/.chezmoiscripts/run_onchange_install-fish.fish.tmpl \
      | /home/testuser/.homebrew/bin/fish
CMD ["/home/testuser/.homebrew/bin/fish"]
