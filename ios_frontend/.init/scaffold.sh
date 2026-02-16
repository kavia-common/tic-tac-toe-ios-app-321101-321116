#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/tic-tac-toe-ios-app-321101-321116/ios_frontend"
mkdir -p "$WS" && cd "$WS"
# load global swift env if present
source /etc/profile.d/swift_ci.sh >/dev/null 2>&1 || true
export CI=true
FORCE=${FORCE_SCAFFOLD:-0}
if [ -f Package.swift ] && [ "${FORCE}" != "1" ]; then
  echo "Package.swift exists; skipping scaffold (set FORCE_SCAFFOLD=1 to overwrite)"
  exit 0
fi
# check swift presence and semantic version
SWVER_RAW=$(command -v swift >/dev/null 2>&1 && swift --version 2>/dev/null | head -n1 || true)
SWVER_SEMVER=$(echo "$SWVER_RAW" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || true)
REQUIRED="5.9"
if [ -z "$SWVER_SEMVER" ]; then
  echo "WARNING: 'swift' not found on PATH; scaffolding will still proceed but swift toolchain may be required for build/test" >&2
else
  inst_major=$(echo "$SWVER_SEMVER" | cut -d. -f1)
  inst_minor=$(echo "$SWVER_SEMVER" | cut -d. -f2)
  req_major=$(echo "$REQUIRED" | cut -d. -f1)
  req_minor=$(echo "$REQUIRED" | cut -d. -f2)
  if [ "$inst_major" -lt "$req_major" ] || ( [ "$inst_major" -eq "$req_major" ] && [ "$inst_minor" -lt "$req_minor" ] ); then
    echo "ERROR: installed Swift ($SWVER_SEMVER) does not support swift-tools-version $REQUIRED" >&2
    exit 2
  fi
fi
# Backup existing files if forced/overwriting
TS=$(date +%s)
if [ -f Package.swift ]; then mv Package.swift Package.swift.bak.$TS; fi
if [ -d Sources ]; then mv Sources Sources.bak.$TS || true; fi
if [ -d Tests ]; then mv Tests Tests.bak.$TS || true; fi
# Create minimal package manifest and sources
cat > Package.swift <<'SW'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "TicTacToeFrontend",
    products: [
        .library(name: "TicTacToeFrontend", targets: ["TicTacToeFrontend"]),
        .executable(name: "ExampleApp", targets: ["ExampleApp"]) 
    ],
    dependencies: [],
    targets: [
        .target(name: "TicTacToeFrontend", path: "Sources/TicTacToeFrontend"),
        .executableTarget(name: "ExampleApp", path: "Sources/ExampleApp", dependencies: ["TicTacToeFrontend"]),
        .testTarget(name: "TicTacToeFrontendTests", dependencies: ["TicTacToeFrontend"], path: "Tests/TicTacToeFrontendTests")
    ]
)
SW
mkdir -p "$WS/Sources/TicTacToeFrontend" "$WS/Sources/ExampleApp" "$WS/Tests/TicTacToeFrontendTests"
cat > "$WS/Sources/TicTacToeFrontend/Game.swift" <<'GO'
public struct Game { public static func greet() -> String { "Hello, TicTacToe" } }
GO
cat > "$WS/Sources/ExampleApp/main.swift" <<'EX'
import Foundation
import TicTacToeFrontend
print(Game.greet())
// short-lived app for validation
sleep(1)
EX
cat > "$WS/Tests/TicTacToeFrontendTests/GameTests.swift" <<'TS'
import XCTest
@testable import TicTacToeFrontend
final class GameTests: XCTestCase {
  func testGreet() { XCTAssertEqual(Game.greet(), "Hello, TicTacToe") }
}
TS
exit 0
