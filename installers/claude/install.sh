#!/usr/bin/env bash
set -euo pipefail

CLAUDE_VERSION="2.1.220"
CLAUDE_INSTALLER_SHA256="cde4f1702d3b1695f92b73d26888364e17bca476e17f0fd676484c951d36c125"

installer=$(mktemp)
curl -fsSL https://claude.ai/install.sh -o "${installer}"
echo "${CLAUDE_INSTALLER_SHA256}  ${installer}" | sha256sum -c
bash "${installer}" "${CLAUDE_VERSION}"
rm "${installer}"
