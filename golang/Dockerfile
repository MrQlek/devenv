FROM golang:1.26.3@sha256:2d6c80227255c3112a4d08e67ba98e58efd3846daf15d9d7d4c389565d881b1a

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
    libgl1-mesa-dev \
    libxcursor-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxi-dev \
    libxxf86vm-dev \
    libx11-dev \
    pkg-config \
    gcc \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g $GROUP_ID dockergo && \
    useradd -u $USER_ID -g $GROUP_ID -m dockergo

RUN mkdir -p /home/dockergo/go && \
    chown -R $USER_ID:$GROUP_ID /home/dockergo/go

RUN mkdir -p /home/dockergo/.cache/go-build && \
    chown -R $USER_ID:$GROUP_ID /home/dockergo/.cache

USER dockergo

ENV GOPATH=/home/dockergo/go
ENV PATH=$PATH:/home/dockergo/go/bin
ENV GIT_OPTIONAL_LOCKS=0

RUN go install golang.org/x/tools/gopls@v0.22.0 && \
    go install github.com/go-delve/delve/cmd/dlv@v1.26.3 && \
    go install github.com/air-verse/air@v1.65.3

RUN echo 'alias dlv-debug="dlv debug --headless --listen=:2345 --api-version=2"' >> /home/dockergo/.bashrc
RUN echo 'alias fd=fdfind' >> /home/dockergo/.bashrc

WORKDIR /workspace
