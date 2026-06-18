FROM node:22-trixie

# Basis-Tools und Build-Abhängigkeiten. Die Build-Deps (build-essential, cmake,
# python3-dev, libffi-dev, libolm-dev, ffmpeg) spiegeln die System-Pakete aus
# dem produktiven hermes-agent Dockerfile — ohne sie scheitern Wheels wie
# python-olm (Matrix) oder native Extras beim `uv pip install`.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    ca-certificates \
    curl \
    wget \
    unzip \
    tree \
    jq \
    vim \
    nano \
    htop \
    sudo \
    lsof \
    net-tools \
    procps \
    strace \
    httpie \
    bash-completion \
    fd-find \
    ripgrep \
    bat \
    locales \
    openssh-client \
    build-essential \
    cmake \
    pkg-config \
    python3-dev \
    libffi-dev \
    libolm-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Generate en_US.UTF-8 locale (avoids "cannot change locale" warnings in bash)
RUN sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install Immeditech certificates (TLS-Inspection-Proxy im Immeditech-Netz)
RUN curl -o /usr/local/share/ca-certificates/Immeditech_Root_CA.crt http://pki.immeditech.ch/static/Immeditech_Root_CA.pem \
    && curl -o /usr/local/share/ca-certificates/Immeditech_TLS_Server_CA.crt http://pki.immeditech.ch/static/Immeditech_TLS_Server_CA.pem \
    && update-ca-certificates

# git-lfs systemweit aktivieren (CONTRIBUTING.md verlangt die LFS-Extension).
RUN git lfs install --system || true

# Setup shell enhancements for better Claude Code experience
RUN echo 'alias ll="ls -la"' >> /etc/bash.bashrc \
    && echo 'alias la="ls -A"' >> /etc/bash.bashrc \
    && echo 'alias l="ls -CF"' >> /etc/bash.bashrc \
    && echo 'alias grep="grep --color=auto"' >> /etc/bash.bashrc

# Create a non-root user for development
RUN useradd -m -s /bin/bash developer \
    && usermod -aG sudo developer \
    && echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /workspace && chown -R developer:developer /workspace
WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to developer user
USER developer
ENV HOME=/home/developer

# uv — Python-Paketmanager des Projekts. Installiert nach ~/.local/bin und bringt
# bei Bedarf selbst die passende Python-Version (pyproject: >=3.11,<3.14) mit.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/developer/.local/bin:${PATH}"

# Claude Code (Native-Build) — installiert nach ~/.local/share/claude/ mit Symlink
# ~/.local/bin/claude. Liegt außerhalb des ~/.claude/-Bind-Mounts und überlebt
# damit Container-Rebuilds. Per-User-State (OAuth, MCP-Liste etc.) lebt separat
# im persistenten ~/.claude/.claude.json — siehe scripts/post-create.sh.
# Updates laufen bei jedem Start via `claude update` (postStartCommand).
RUN curl -fsSL https://claude.ai/install.sh | bash

CMD ["/entrypoint.sh"]
