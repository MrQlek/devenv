ARG GO_RELEASE
FROM golang:${GO_RELEASE}

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

RUN groupadd -g $GROUP_ID dockergo && \
    useradd -u $USER_ID -g $GROUP_ID -m dockergo

RUN mkdir -p /home/dockergo/go && \
    chown -R $USER_ID:$GROUP_ID /home/dockergo/go

USER dockergo

ENV GOPATH=/home/dockergo/go
ENV PATH=$PATH:/home/dockergo/go/bin

RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install github.com/air-verse/air@latest

RUN echo 'alias dlv-debug="dlv debug --headless --listen=:2345 --api-version=2"' >> /home/dockergo/.bashrc
RUN echo 'alias fd=fdfind' >> /home/dockergo/.bashrc

WORKDIR /workspace