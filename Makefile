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

BASE ?= dev

list-golang-tags:
	@git tag --list "golang/*"

list-golang-claude-tags:
	@git tag --list "golang-claude/*"

build-golang:
	@if [ -z "$(GOLANG_VERSION)" ]; then echo "No golang/* tag on this commit"; exit 1; fi
	@echo "Building golang-dev:$(GOLANG_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t golang-dev:$(GOLANG_VERSION) \
	  golang/

build-golang-dev:
	@echo "Building golang-dev:dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t golang-dev:dev \
	  golang/

build-golang-claude:
	@if [ -z "$(GOLANG_CLAUDE_VERSION)" ]; then echo "No golang-claude/* tag on this commit"; exit 1; fi
	@if [ -z "$(GOLANG_BASE_VERSION)" ]; then echo "No golang/* tag reachable from HEAD"; exit 1; fi
	@if ! docker image inspect golang-dev:$(GOLANG_BASE_VERSION) > /dev/null 2>&1; then \
	    echo "Base image golang-dev:$(GOLANG_BASE_VERSION) not found. Build it from commit tagged $(GOLANG_BASE_VERSION)."; \
	    exit 1; \
	fi
	@echo "Building golang-claude-dev:$(GOLANG_CLAUDE_VERSION) on golang-dev:$(GOLANG_BASE_VERSION)"
	docker build \
	  --build-arg BASE_VERSION=$(GOLANG_BASE_VERSION) \
	  -t golang-claude-dev:$(GOLANG_CLAUDE_VERSION) \
	  -f golang-claude/Dockerfile \
	  .

build-golang-claude-dev:
	@if ! docker image inspect golang-dev:$(BASE) > /dev/null 2>&1; then \
	    echo "Base image golang-dev:$(BASE) not found."; \
	    if [ "$(BASE)" = "dev" ]; then echo "Run: make build-golang-dev"; \
	    else echo "Build it from the commit tagged golang/$(BASE), or pass BASE=<version>."; fi; \
	    exit 1; \
	fi
	@echo "Building golang-claude-dev:dev on golang-dev:$(BASE)"
	docker build \
	  --build-arg BASE_VERSION=$(BASE) \
	  -t golang-claude-dev:dev \
	  -f golang-claude/Dockerfile \
	  .
