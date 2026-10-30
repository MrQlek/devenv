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
    procps \
    psmisc \
    lsof \
    tree \
    && rm -rf /var/lib/apt/lists/*

# pycairo and ManimPango publish no Linux wheels, so uv builds them from source against these.
# ffmpeg is used by the template's tools/ scripts to extract stills and join scenes into movies.
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libcairo2-dev \
    libpango1.0-dev \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Curated TeX set for Tex/MathTex — covers manim's default templates without texlive-full.
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-science \
    cm-super \
    dvisvgm \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.11.19@sha256:b46b03ddfcfbf8f547af7e9eaefdf8a39c8cebcba7c98858d3162bd28cf536f6 /uv /uvx /usr/local/bin/

# manim itself is not installed here — projects pin it via uv (see templates/manim/).
COPY templates/manim/ /opt/devenv/templates/manim/
COPY images/manim/manim-init /usr/local/bin/manim-init
RUN chmod -R a+rX /opt/devenv/templates/manim && chmod 755 /usr/local/bin/manim-init

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

RUN echo 'alias fd=fdfind' >> /home/devuser/.bashrc

WORKDIR /workspace
