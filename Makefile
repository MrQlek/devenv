ifdef SUDO_USER
    UID := $(shell id -u $(SUDO_USER))
    GID := $(shell id -g $(SUDO_USER))
else
    UID := $(shell id -u)
    GID := $(shell id -g)
endif

IMAGE_VERSION := $(shell git describe --tags --match "golang/*" --exact-match 2>/dev/null)

list-golang-tags:
	@git tag --list "golang/*"

build-golang:
	@if [ -z "$(IMAGE_VERSION)" ]; then echo "No golang tag on this commit"; exit 1; fi
	@echo "Building golang-dev:$(IMAGE_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t golang-dev:$(IMAGE_VERSION) \
	  golang/

build-golang-dev:
	@echo "Building golang-dev:dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  -t golang-dev:dev \
	  golang/

build-golang-claude:
	@if [ -z "$(IMAGE_VERSION)" ]; then echo "No golang tag on this commit"; exit 1; fi
	@if ! docker image inspect golang-dev:$(IMAGE_VERSION) > /dev/null 2>&1; then \
	    echo "Base image golang-dev:$(IMAGE_VERSION) not found. Run: make build-golang"; \
	    exit 1; \
	fi
	@echo "Building golang-claude-dev:$(IMAGE_VERSION)"
	docker build \
	  --build-arg IMAGE_VERSION=$(IMAGE_VERSION) \
	  -t golang-claude-dev:$(IMAGE_VERSION) \
	  -f golang-claude/Dockerfile \
	  .

build-golang-claude-dev:
	@if ! docker image inspect golang-dev:dev > /dev/null 2>&1; then \
	    echo "Base image golang-dev:dev not found. Run: make build-golang-dev"; \
	    exit 1; \
	fi
	@echo "Building golang-claude-dev:dev"
	docker build \
	  --build-arg IMAGE_VERSION=dev \
	  -t golang-claude-dev:dev \
	  -f golang-claude/Dockerfile \
	  .
