ARG IMAGE_VERSION=dev

FROM golang-dev:${IMAGE_VERSION}

USER dockergo

COPY installers/claude/install.sh /tmp/install-claude.sh
RUN bash /tmp/install-claude.sh && rm /tmp/install-claude.sh

ENV PATH="/home/dockergo/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1
