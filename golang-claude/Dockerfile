ARG IMAGE_VERSION=dev

FROM golang-dev:${IMAGE_VERSION}

USER dockergo

RUN curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh \
    && echo "b315b46925a9bfb9422f2503dd5aa649f680832f4c076b22d87c39d578c3d830  /tmp/claude-install.sh" | sha256sum -c \
    && bash /tmp/claude-install.sh 2.1.150 \
    && rm /tmp/claude-install.sh

ENV PATH="/home/dockergo/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1
