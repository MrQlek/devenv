#!/usr/bin/env bash
set -euo pipefail

CLAUDE_VERSION="2.1.150"
CLAUDE_INSTALLER_SHA256="005ec1a937f32dfbb74f9e810287bcb12cba2d5cae4c9277aa8c6364adbf1787"

installer=$(mktemp)
curl -fsSL https://claude.ai/install.sh -o "${installer}"
echo "${CLAUDE_INSTALLER_SHA256}  ${installer}" | sha256sum -c
bash "${installer}" "${CLAUDE_VERSION}"
rm "${installer}"
