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
PYTHON_VERSION        := $(shell git describe --tags --match "python/*" --exact-match 2>/dev/null)
PYTHON_CLAUDE_VERSION := $(shell git describe --tags --match "python-claude/*" --exact-match 2>/dev/null)
PYTHON_BASE_VERSION   := $(shell git describe --tags --match "python/*" --abbrev=0 2>/dev/null)
TYPESCRIPT_VERSION        := $(shell git describe --tags --match "typescript/*" --exact-match 2>/dev/null)
TYPESCRIPT_CLAUDE_VERSION := $(shell git describe --tags --match "typescript-claude/*" --exact-match 2>/dev/null)
TYPESCRIPT_BASE_VERSION   := $(shell git describe --tags --match "typescript/*" --abbrev=0 2>/dev/null)
HUGO_VERSION        := $(shell git describe --tags --match "hugo/*" --exact-match 2>/dev/null)
HUGO_CLAUDE_VERSION := $(shell git describe --tags --match "hugo-claude/*" --exact-match 2>/dev/null)
HUGO_BASE_VERSION   := $(shell git describe --tags --match "hugo/*" --abbrev=0 2>/dev/null)

DEV_BASE ?= dev

list-golang-tags:
	@git tag --list "golang/*"

list-python-tags:
	@git tag --list "python/*"

list-typescript-tags:
	@git tag --list "typescript/*"

list-golang-claude-tags:
	@git tag --list "golang-claude/*"

list-python-claude-tags:
	@git tag --list "python-claude/*"

list-typescript-claude-tags:
	@git tag --list "typescript-claude/*"

list-hugo-tags:
	@git tag --list "hugo/*"

list-hugo-claude-tags:
	@git tag --list "hugo-claude/*"

build-golang:
	@if [ -z "$(GOLANG_VERSION)" ]; then echo "No golang/* tag on this commit"; exit 1; fi
	@echo "Building devenv-image-golang:$(GOLANG_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-golang:$(GOLANG_VERSION) \
	  images/golang/

build-golang-dev:
	@echo "Building devenv-image-golang:dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-golang:dev \
	  images/golang/

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
	  -f images/golang-claude/Dockerfile \
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
	  -f images/golang-claude/Dockerfile \
	  .

build-python:
	@if [ -z "$(PYTHON_VERSION)" ]; then echo "No python/* tag on this commit"; exit 1; fi
	@echo "Building devenv-image-python:$(PYTHON_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-python:$(PYTHON_VERSION) \
	  images/python/

build-python-dev:
	@echo "Building devenv-image-python:dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-python:dev \
	  images/python/

build-python-claude:
	@if [ -z "$(PYTHON_CLAUDE_VERSION)" ]; then echo "No python-claude/* tag on this commit"; exit 1; fi
	@if [ -z "$(PYTHON_BASE_VERSION)" ]; then echo "No python/* tag reachable from HEAD"; exit 1; fi
	@if ! docker image inspect devenv-image-python:$(PYTHON_BASE_VERSION) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-python:$(PYTHON_BASE_VERSION) not found. Build it from commit tagged $(PYTHON_BASE_VERSION)."; \
	    exit 1; \
	fi
	@echo "Building devenv-image-python-claude:$(PYTHON_CLAUDE_VERSION) on devenv-image-python:$(PYTHON_BASE_VERSION)"
	docker build \
	  --build-arg BASE_VERSION=$(PYTHON_BASE_VERSION) \
	  -t devenv-image-python-claude:$(PYTHON_CLAUDE_VERSION) \
	  -f images/python-claude/Dockerfile \
	  .

build-python-claude-dev:
	@if ! docker image inspect devenv-image-python:$(DEV_BASE) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-python:$(DEV_BASE) not found."; \
	    if [ "$(DEV_BASE)" = "dev" ]; then echo "Run: make build-python-dev"; \
	    else echo "Build it from the commit tagged python/$(DEV_BASE), or pass DEV_BASE=<version>."; fi; \
	    exit 1; \
	fi
	@echo "Building devenv-image-python-claude:dev on devenv-image-python:$(DEV_BASE)"
	docker build \
	  --build-arg BASE_VERSION=$(DEV_BASE) \
	  -t devenv-image-python-claude:dev \
	  -f images/python-claude/Dockerfile \
	  .

build-typescript:
	@if [ -z "$(TYPESCRIPT_VERSION)" ]; then echo "No typescript/* tag on this commit"; exit 1; fi
	@echo "Building devenv-image-typescript:$(TYPESCRIPT_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-typescript:$(TYPESCRIPT_VERSION) \
	  images/typescript/

build-typescript-dev:
	@echo "Building devenv-image-typescript:dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-typescript:dev \
	  images/typescript/

build-typescript-claude:
	@if [ -z "$(TYPESCRIPT_CLAUDE_VERSION)" ]; then echo "No typescript-claude/* tag on this commit"; exit 1; fi
	@if [ -z "$(TYPESCRIPT_BASE_VERSION)" ]; then echo "No typescript/* tag reachable from HEAD"; exit 1; fi
	@if ! docker image inspect devenv-image-typescript:$(TYPESCRIPT_BASE_VERSION) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-typescript:$(TYPESCRIPT_BASE_VERSION) not found. Build it from commit tagged $(TYPESCRIPT_BASE_VERSION)."; \
	    exit 1; \
	fi
	@echo "Building devenv-image-typescript-claude:$(TYPESCRIPT_CLAUDE_VERSION) on devenv-image-typescript:$(TYPESCRIPT_BASE_VERSION)"
	docker build \
	  --build-arg BASE_VERSION=$(TYPESCRIPT_BASE_VERSION) \
	  -t devenv-image-typescript-claude:$(TYPESCRIPT_CLAUDE_VERSION) \
	  -f images/typescript-claude/Dockerfile \
	  .

build-typescript-claude-dev:
	@if ! docker image inspect devenv-image-typescript:$(DEV_BASE) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-typescript:$(DEV_BASE) not found."; \
	    if [ "$(DEV_BASE)" = "dev" ]; then echo "Run: make build-typescript-dev"; \
	    else echo "Build it from the commit tagged typescript/$(DEV_BASE), or pass DEV_BASE=<version>."; fi; \
	    exit 1; \
	fi
	@echo "Building devenv-image-typescript-claude:dev on devenv-image-typescript:$(DEV_BASE)"
	docker build \
	  --build-arg BASE_VERSION=$(DEV_BASE) \
	  -t devenv-image-typescript-claude:dev \
	  -f images/typescript-claude/Dockerfile \
	  .

# Unlike the other base-language images, hugo/Dockerfile COPYs installers/hugo/install.sh,
# so it needs the repo root as build context rather than images/hugo/.
build-hugo:
	@if [ -z "$(HUGO_VERSION)" ]; then echo "No hugo/* tag on this commit"; exit 1; fi
	@echo "Building devenv-image-hugo:$(HUGO_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-hugo:$(HUGO_VERSION) \
	  -f images/hugo/Dockerfile \
	  .

build-hugo-dev:
	@echo "Building devenv-image-hugo:dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t devenv-image-hugo:dev \
	  -f images/hugo/Dockerfile \
	  .

build-hugo-claude:
	@if [ -z "$(HUGO_CLAUDE_VERSION)" ]; then echo "No hugo-claude/* tag on this commit"; exit 1; fi
	@if [ -z "$(HUGO_BASE_VERSION)" ]; then echo "No hugo/* tag reachable from HEAD"; exit 1; fi
	@if ! docker image inspect devenv-image-hugo:$(HUGO_BASE_VERSION) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-hugo:$(HUGO_BASE_VERSION) not found. Build it from commit tagged $(HUGO_BASE_VERSION)."; \
	    exit 1; \
	fi
	@echo "Building devenv-image-hugo-claude:$(HUGO_CLAUDE_VERSION) on devenv-image-hugo:$(HUGO_BASE_VERSION)"
	docker build \
	  --build-arg BASE_VERSION=$(HUGO_BASE_VERSION) \
	  -t devenv-image-hugo-claude:$(HUGO_CLAUDE_VERSION) \
	  -f images/hugo-claude/Dockerfile \
	  .

build-hugo-claude-dev:
	@if ! docker image inspect devenv-image-hugo:$(DEV_BASE) > /dev/null 2>&1; then \
	    echo "Base image devenv-image-hugo:$(DEV_BASE) not found."; \
	    if [ "$(DEV_BASE)" = "dev" ]; then echo "Run: make build-hugo-dev"; \
	    else echo "Build it from the commit tagged hugo/$(DEV_BASE), or pass DEV_BASE=<version>."; fi; \
	    exit 1; \
	fi
	@echo "Building devenv-image-hugo-claude:dev on devenv-image-hugo:$(DEV_BASE)"
	docker build \
	  --build-arg BASE_VERSION=$(DEV_BASE) \
	  -t devenv-image-hugo-claude:dev \
	  -f images/hugo-claude/Dockerfile \
	  .
