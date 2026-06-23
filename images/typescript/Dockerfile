FROM node:24.16.0-bookworm-slim@sha256:242549cd46785b480c832479a730f4f2a20865d61ea2e404fdb2a5c3d3b73ecf

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

# node:bookworm-slim ships a uid-1000 `node` user; drop it so devuser can claim uid 1000.
RUN userdel -r node 2>/dev/null || true && \
    groupadd -g $GROUP_ID devuser && \
    useradd -u $USER_ID -g $GROUP_ID -m devuser

RUN mkdir -p /home/devuser/.npm \
             /home/devuser/.expo \
             /home/devuser/.npm-global/bin && \
    chown -R $USER_ID:$GROUP_ID /home/devuser/.npm \
                                 /home/devuser/.expo \
                                 /home/devuser/.npm-global

USER devuser

ENV NPM_CONFIG_PREFIX=/home/devuser/.npm-global
ENV PATH=/home/devuser/.npm-global/bin:$PATH

RUN npm install -g \
    typescript@6.0.3 \
    tsx@4.22.4 \
    @vscode/vsce@3.9.1 \
    eas-cli@20.0.0

# ts-debug:   tsc compile + node --inspect-brk on the compiled JS (recommended for TS).
# node-debug: plain JS, no transpile.
# tsx-debug:  TypeScript via tsx (fast, but its worker model interacts badly with --inspect-brk;
#             use only if you know how to navigate threads in the VS Code debugger).
RUN echo 'alias ts-debug="tsc && node --inspect-brk=0.0.0.0:9229"' >> /home/devuser/.bashrc
RUN echo 'alias node-debug="node --inspect-brk=0.0.0.0:9229"' >> /home/devuser/.bashrc
RUN echo 'alias tsx-debug="tsx --inspect-brk=0.0.0.0:9229"' >> /home/devuser/.bashrc
RUN echo 'alias fd=fdfind' >> /home/devuser/.bashrc

WORKDIR /workspace
