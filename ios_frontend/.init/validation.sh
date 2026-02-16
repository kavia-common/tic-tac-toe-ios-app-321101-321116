#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/tic-tac-toe-ios-app-321101-321116/ios_frontend"
cd "$WS"
# Load persisted env if present
# shellcheck disable=SC1090
source /etc/profile.d/swift_ci.sh || true
export CI=true
EXE_TIMEOUT=${EXE_TIMEOUT:-10}
# Build (debug)
if ! command -v swift >/dev/null 2>&1; then echo "ERROR: swift not found on PATH" >&2; exit 2; fi
swift build -c debug
# Run tests
if ! swift test -v; then echo "ERROR: tests failed" >&2; exit 3; fi
# Locate executable
EXE_PATH="$WS/.build/debug/ExampleApp"
if [ ! -x "$EXE_PATH" ]; then echo "ERROR: executable not found at $EXE_PATH" >&2; exit 4; fi
LOG=$(mktemp -t exampleapp.XXXX)
# Start app, capture stdout/stderr
"$EXE_PATH" >"$LOG" 2>&1 &
PID=$!
# Wait up to EXE_TIMEOUT seconds for expected greeting
SEEN=0
for i in $(seq 1 "$EXE_TIMEOUT"); do
  if head -n1 "$LOG" | grep -q "Hello, TicTacToe"; then SEEN=1; break; fi
  sleep 1
done
if [ "$SEEN" -ne 1 ]; then
  echo "ERROR: ExampleApp did not produce expected output within ${EXE_TIMEOUT}s" >&2
  kill "$PID" 2>/dev/null || true
  sleep 1
  kill -9 "$PID" 2>/dev/null || true
  rm -f "$LOG"
  exit 5
fi
FIRST_LINE=$(head -n1 "$LOG" || true)
echo "ExampleApp output verified: $FIRST_LINE"
# Clean up: stop process if still running
if kill -0 "$PID" >/dev/null 2>&1; then
  kill "$PID" || true
  wait "$PID" 2>/dev/null || true
fi
rm -f "$LOG"
cat <<'ADV'
NOTE: This container supports Swift compilation, swift build and XCTest unit testing only. Building, signing, or running on iOS simulators or devices requires macOS and Xcode (code signing/provisioning are out of scope for this environment).
ADV
exit 0
