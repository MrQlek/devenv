ARG IMAGE_VERSION=dev

FROM golang-dev:${IMAGE_VERSION}

USER dockergo

RUN curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh \
    && echo "005ec1a937f32dfbb74f9e810287bcb12cba2d5cae4c9277aa8c6364adbf1787 /tmp/claude-install.sh" | sha256sum -c \
    && bash /tmp/claude-install.sh 2.1.150 \
    && rm /tmp/claude-install.sh

ENV PATH="/home/dockergo/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1
