ifdef SUDO_USER
    UID := $(shell id -u $(SUDO_USER))
    GID := $(shell id -g $(SUDO_USER))
else
    UID := $(shell id -u)
    GID := $(shell id -g)
endif

GOLANG_VERSION        := $(shell git describe --tags --match "golang/*" --exact-match 2>/dev/null)
GOLANG_CLAUDE_VERSION := $(shell git describe --tags --match "golang-claude/*" --exact-match 2>/dev/null)
GOLANG_BASE_VERSION   := $(shell git describe --tags --match "golang/*" --abbrev=0 2>/dev/null)

DEV_BASE ?= dev

list-golang-tags:
	@git tag --list "golang/*"

list-golang-claude-tags:
	@git tag --list "golang-claude/*"

build-golang:
	@if [ -z "$(GOLANG_VERSION)" ]; then echo "No golang/* tag on this commit"; exit 1; fi
	@echo "Building devenv-image-golang:$(GOLANG_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-golang:$(GOLANG_VERSION) \
	  golang/

build-golang-dev:
	@echo "Building devenv-image-golang:dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-golang:dev \
	  golang/

build-golang-claude:
	@if [ -z "$(GOLANG_CLAUDE_VERSION)" ]; then echo "No golang-claude/* tag on this commit"; exit 1; fi
	@if [ -z "$(GOLANG_BASE_VERSION)" ]; then echo "No golang/* tag reachable from HEAD"; exit 1; fi
	@if ! docker image inspect devenv-image-golang:$(GOLANG_BASE_VERSION) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-golang:$(GOLANG_BASE_VERSION) not found. Build it from commit tagged $(GOLANG_BASE_VERSION)."; \
	    exit 1; \
	fi
	@echo "Building devenv-image-golang-claude:$(GOLANG_CLAUDE_VERSION) on devenv-image-golang:$(GOLANG_BASE_VERSION)"
	docker build \
	  --build-arg BASE_VERSION=$(GOLANG_BASE_VERSION) \
	  -t devenv-image-golang-claude:$(GOLANG_CLAUDE_VERSION) \
	  -f golang-claude/Dockerfile \
	  .

build-golang-claude-dev:
	@if ! docker image inspect devenv-image-golang:$(DEV_BASE) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-golang:$(DEV_BASE) not found."; \
	    if [ "$(DEV_BASE)" = "dev" ]; then echo "Run: make build-golang-dev"; \
	    else echo "Build it from the commit tagged golang/$(DEV_BASE), or pass DEV_BASE=<version>."; fi; \
	    exit 1; \
	fi
	@echo "Building devenv-image-golang-claude:dev on devenv-image-golang:$(DEV_BASE)"
	docker build \
	  --build-arg BASE_VERSION=$(DEV_BASE) \
	  -t devenv-image-golang-claude:dev \
	  -f golang-claude/Dockerfile \
	  .
