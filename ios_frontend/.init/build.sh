#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/tic-tac-toe-ios-app-321101-321116/ios_frontend"
cd "$WS"
# Source global swift environment if present (no-op if missing)
# shellcheck disable=SC1090
source /etc/profile.d/swift_ci.sh || true
export CI=true
# Ensure swift is available
if ! command -v swift >/dev/null 2>&1; then
  echo "error: 'swift' not found on PATH. Ensure Swift toolchain is installed and /etc/profile.d/swift_ci.sh sets PATH or install swift in the container." >&2
  exit 2
fi
# Fail fast: resolve package graph and perform a quick debug build
swift package resolve
swift build -c debug
echo "build verified"
