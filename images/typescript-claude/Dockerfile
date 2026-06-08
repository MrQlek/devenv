ARG BASE_VERSION=dev

FROM devenv-image-typescript:${BASE_VERSION}

USER devuser

COPY --chown=devuser:devuser installers/claude/install.sh /tmp/install-claude.sh
RUN bash /tmp/install-claude.sh && rm /tmp/install-claude.sh

ENV PATH="/home/devuser/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1
