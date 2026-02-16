#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/tic-tac-toe-ios-app-321101-321116/ios_frontend"
cd "$WS"
# source global swift environment if present
# shellcheck disable=SC1090
source /etc/profile.d/swift_ci.sh || true
export CI=true
# Fail early with a helpful message if swift is not available
if ! command -v swift >/dev/null 2>&1; then
  echo "error: swift not found on PATH. Ensure the Swift toolchain is installed and /etc/profile.d/swift_ci.sh sets PATH or run the env/install step." >&2
  exit 2
fi
# Run tests verbosely so CI logs capture failures; fail-fast via set -e
swift test -v
