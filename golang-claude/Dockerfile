ARG GO_RELEASE
ARG IMAGE_VERSION=dev
ARG NODE_VERSION=24.14.1

FROM golang-dev:${GO_RELEASE}-${IMAGE_VERSION}

USER dockergo

RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/home/dockergo/.local/bin:${PATH}"
