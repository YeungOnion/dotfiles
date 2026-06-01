FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    fish \
    gawk \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /usr/bin/fish testuser

USER testuser
WORKDIR /home/testuser

RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /home/testuser/.local/bin

ENV PATH="/home/testuser/.local/bin:$PATH"

COPY --chown=testuser:testuser . /home/testuser/.local/share/chezmoi/

# Apply file state only — skip install scripts (brew, packages, cargo, etc.)
RUN chezmoi apply --exclude scripts

CMD ["fish"]
