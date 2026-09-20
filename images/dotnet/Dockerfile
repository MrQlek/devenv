FROM mcr.microsoft.com/dotnet/sdk:10.0.400-noble@sha256:e1ffd2a92ae84c1291bc1b6887501f8af98e6331e7af6d4c8d37168c5e87a64c

ARG USER_ID=1000
ARG GROUP_ID=1000

# libfontconfig1 + fonts-dejavu-core are the only GUI-adjacent packages here: SkiaSharp
# (pulled in by Avalonia) links against system fontconfig, so Avalonia.Headless UI tests
# fail to load libSkiaSharp without them. Everything else Avalonia/Photino need ships
# inside their NuGet packages and is restored per-project.
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
    libfontconfig1 \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu noble ships a uid/gid-1000 `ubuntu` user; drop it so devuser can claim uid 1000.
# (The old bookworm-slim base had no uid-1000 user, so this wasn't needed before.)
RUN userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g $GROUP_ID devuser && \
    useradd -u $USER_ID -g $GROUP_ID -m devuser

RUN mkdir -p /home/devuser/.nuget/packages \
             /home/devuser/.dotnet/tools \
             /home/devuser/.templateengine && \
    chown -R $USER_ID:$GROUP_ID /home/devuser/.nuget \
                                /home/devuser/.dotnet \
                                /home/devuser/.templateengine

USER devuser

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
ENV NUGET_PACKAGES=/home/devuser/.nuget/packages
ENV PATH=$PATH:/home/devuser/.dotnet/tools

RUN echo 'alias fd=fdfind' >> /home/devuser/.bashrc

WORKDIR /workspace
