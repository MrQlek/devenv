#!/usr/bin/env bash
set -euo pipefail

CLAUDE_VERSION="2.1.325"

installer=$(mktemp)
curl -fsSL https://claude.ai/install.sh -o "${installer}"
bash "${installer}" "${CLAUDE_VERSION}"
rm "${installer}"
