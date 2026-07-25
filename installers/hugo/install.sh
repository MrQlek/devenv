#!/usr/bin/env bash
set -euo pipefail

HUGO_VERSION="0.164.0"
HUGO_ARCHIVE_SHA256="fea17b8c076f950bb2e9f9486667bdaa29422883888d509d63931c73e8a9b3a4"

archive=$(mktemp)
curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz" -o "${archive}"
echo "${HUGO_ARCHIVE_SHA256}  ${archive}" | sha256sum -c
tar -xzf "${archive}" -C /usr/local/bin hugo
chmod +x /usr/local/bin/hugo
rm "${archive}"
