FROM python:3.14.5-slim-bookworm@sha256:a9bee15510a364124aa24692899d269835683b883de42f7ebec8c293cf679ccb

ARG USER_ID=1000
ARG GROUP_ID=1000

RUN apt-get update && apt-get install -y \
    make \
    curl \
    wget \
    git \
    fzf \
    ripgrep \
    fd-find \
    jq \
    vim \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.11.19@sha256:b46b03ddfcfbf8f547af7e9eaefdf8a39c8cebcba7c98858d3162bd28cf536f6 /uv /uvx /usr/local/bin/

# Install into system Python so tools are always available regardless of project venv
RUN pip install --no-cache-dir \
    debugpy==1.8.21 \
    ruff==0.15.16 \
    mypy==2.1.0

RUN groupadd -g $GROUP_ID devuser && \
    useradd -u $USER_ID -g $GROUP_ID -m devuser

RUN mkdir -p /home/devuser/.cache/uv \
             /home/devuser/.local/bin \
             /home/devuser/.local/share/uv \
             /home/devuser/.uv-tools/bin && \
    chown -R $USER_ID:$GROUP_ID /home/devuser/.cache \
                                 /home/devuser/.local \
                                 /home/devuser/.uv-tools

USER devuser

ENV UV_CACHE_DIR=/home/devuser/.cache/uv
# uv tool shims go to ~/.uv-tools/bin so ~/.local/bin stays free for Claude Code
ENV UV_TOOL_BIN_DIR=/home/devuser/.uv-tools/bin
ENV PATH=$PATH:/home/devuser/.local/bin:/home/devuser/.uv-tools/bin

# py-debug: uses system Python (always works, ignores project venv)
# py-debug-uv: uses project's uv venv (respects project dependencies)
RUN echo 'alias py-debug="python -m debugpy --listen 0.0.0.0:5678 --wait-for-client"' >> /home/devuser/.bashrc
RUN echo 'alias py-debug-uv="uv run --with debugpy python -m debugpy --listen 0.0.0.0:5678 --wait-for-client"' >> /home/devuser/.bashrc
RUN echo 'alias fd=fdfind' >> /home/devuser/.bashrc

WORKDIR /workspace
