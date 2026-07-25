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
    procps \
    psmisc \
    lsof \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Extended build (embedded Sass) is required for the SCSS pipelines used by most themes.
COPY installers/hugo/install.sh /tmp/install-hugo.sh
RUN bash /tmp/install-hugo.sh && rm /tmp/install-hugo.sh

RUN groupadd -g $GROUP_ID devuser && \
    useradd -u $USER_ID -g $GROUP_ID -m devuser

# Go toolchain is required for Hugo Modules (`hugo mod`), which shells out to `go mod` internally.
RUN mkdir -p /home/devuser/go && \
    chown -R $USER_ID:$GROUP_ID /home/devuser/go

RUN mkdir -p /home/devuser/.cache/go-build \
             /home/devuser/.cache/hugo && \
    chown -R $USER_ID:$GROUP_ID /home/devuser/.cache

USER devuser

ENV GOPATH=/home/devuser/go
ENV PATH=$PATH:/home/devuser/go/bin
ENV GIT_OPTIONAL_LOCKS=0
ENV HUGO_CACHEDIR=/home/devuser/.cache/hugo

RUN echo 'alias fd=fdfind' >> /home/devuser/.bashrc

WORKDIR /workspace
