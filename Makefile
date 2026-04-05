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
	@if [ -z "$(GO_RELEASE)" ]; then echo "GO_RELEASE is required, e.g. make build-golang GO_RELEASE=1.26"; exit 1; fi
	@if [ -z "$(IMAGE_VERSION)" ]; then echo "No golang tag on this commit"; exit 1; fi
	@echo "Building golang-dev:$(GO_RELEASE)-$(IMAGE_VERSION)"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  --build-arg GO_RELEASE=$(GO_RELEASE) \
	  -t golang-dev:$(GO_RELEASE)-$(IMAGE_VERSION) \
	  golang/

build-golang-dev:
	@if [ -z "$(GO_RELEASE)" ]; then echo "GO_RELEASE is required, e.g. make build-golang-dev GO_RELEASE=1.26"; exit 1; fi
	@echo "Building golang-dev:$(GO_RELEASE)-dev"
	docker build \
	  --build-arg USER_ID=$(UID) \
	  --build-arg GROUP_ID=$(GID) \
	  --build-arg GO_RELEASE=$(GO_RELEASE) \
	  -t golang-dev:$(GO_RELEASE)-dev \
	  golang/
