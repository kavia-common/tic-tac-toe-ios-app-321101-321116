#!/usr/bin/env bash
set -euo pipefail
# environment - install Swift toolchain and configure global env
WS="/home/kavia/workspace/code-generation/tic-tac-toe-ios-app-321101-321116/ios_frontend"
: ${CI:=true}
export CI
: ${SWIFT_TGZ:=}
: ${SWIFT_URL:=""}
: ${SWIFT_RELEASE_BASE:=""}
: ${SWIFT_VERSION:=""}
: ${SWIFT_DIR_BASE:=/usr/local}
: ${SWIFT_REQUIRED_TOOLS_VERSION:=5.9}
# Build SWIFT_URL if not provided but SWIFT_RELEASE_BASE is provided
if [ -z "${SWIFT_URL:-}" ]; then
  if [ -n "${SWIFT_RELEASE_BASE:-}" ]; then
    : ${SWIFT_TGZ:=${SWIFT_RELEASE_BASE}.tar.gz}
    SWIFT_URL="https://swift.org/builds/${SWIFT_RELEASE_BASE%/*}/${SWIFT_RELEASE_BASE}/ubuntu2404/${SWIFT_TGZ}"
  else
    echo "ERROR: SWIFT_URL or SWIFT_RELEASE_BASE must be set to a valid swift tarball URL" >&2
    exit 2
  fi
fi
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq && sudo apt-get install -y --no-install-recommends -qq clang ca-certificates libssl-dev libcurl4-openssl-dev libsqlite3-dev
TMP_ARCHIVE="/tmp/swift-download.tgz"
EXTRACT_DIR="/tmp/swift-extract-$$"
sudo rm -rf "$EXTRACT_DIR" && mkdir -p "$EXTRACT_DIR"
# Derive SWIFT_VERSION label if not provided
if [ -z "${SWIFT_VERSION:-}" ]; then
  if [ -n "${SWIFT_RELEASE_BASE:-}" ]; then SWIFT_VERSION="$SWIFT_RELEASE_BASE"; else SWIFT_VERSION="custom"; fi
fi
SWIFT_DIR="$SWIFT_DIR_BASE/swift-${SWIFT_VERSION}"
SW_CURRENT="$SWIFT_DIR_BASE/swift-current"
if [ ! -x "$SWIFT_DIR/usr/bin/swift" ]; then
  curl -fsSL --connect-timeout 10 --max-time 300 "$SWIFT_URL" -o "$TMP_ARCHIVE"
  TOP_DIR=$(tar -tf "$TMP_ARCHIVE" | head -n1 | cut -d/ -f1 || true)
  if [ -z "$TOP_DIR" ]; then
    echo "ERROR: unable to determine top-level directory in Swift tarball" >&2
    rm -f "$TMP_ARCHIVE"
    exit 3
  fi
  sudo tar -C "$EXTRACT_DIR" -xzf "$TMP_ARCHIVE"
  sudo rm -rf "$SWIFT_DIR" || true
  sudo mv "$EXTRACT_DIR/$TOP_DIR" "$SWIFT_DIR"
  sudo ln -sfn "$SWIFT_DIR" "$SW_CURRENT"
  sudo chmod -R a+rX "$SWIFT_DIR"
  rm -f "$TMP_ARCHIVE"
  rm -rf "$EXTRACT_DIR"
fi
# Persist environment for all users/sessions
sudo tee /etc/profile.d/swift_ci.sh >/dev/null <<'EOF'
export CI=true
export SWIFT_HOME=/usr/local/swift-current
case ":$PATH:" in
  *:/usr/local/swift-current/usr/bin:*) ;;
  *) export PATH="/usr/local/swift-current/usr/bin:$PATH";;
esac
export PATH
EOF
sudo chmod +x /etc/profile.d/swift_ci.sh
# Load and validate
# shellcheck disable=SC1090
source /etc/profile.d/swift_ci.sh || true
if ! command -v swift >/dev/null 2>&1; then echo "ERROR: swift not found on PATH" >&2; exit 4; fi
if ! command -v swiftc >/dev/null 2>&1; then echo "ERROR: swiftc not found on PATH" >&2; exit 5; fi
if ! swift package help >/dev/null 2>&1; then echo "ERROR: 'swift package' subcommand not available" >&2; exit 6; fi
SWVER_RAW=$(swift --version 2>/dev/null | head -n1 || true)
SWVER_SEMVER=$(echo "$SWVER_RAW" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || true)
if [ -z "$SWVER_SEMVER" ]; then echo "WARNING: could not parse Swift semantic version from: $SWVER_RAW" >&2; else echo "$SWVER_RAW"; fi
# Compare semantic versions (major.minor)
req_major=$(echo "$SWIFT_REQUIRED_TOOLS_VERSION" | cut -d. -f1)
req_minor=$(echo "$SWIFT_REQUIRED_TOOLS_VERSION" | cut -d. -f2)
inst_major=$(echo "$SWVER_SEMVER" | cut -d. -f1 || echo 0)
inst_minor=$(echo "$SWVER_SEMVER" | cut -d. -f2 || echo 0)
if [ -n "$SWVER_SEMVER" ] && ( [ "$inst_major" -lt "$req_major" ] || ( [ "$inst_major" -eq "$req_major" ] && [ "$inst_minor" -lt "$req_minor" ] ) ); then
  echo "ERROR: installed Swift ($SWVER_SEMVER) is older than required tools-version $SWIFT_REQUIRED_TOOLS_VERSION" >&2
  exit 7
fi
# Note on ownership: /usr/local/swift-* files are owned by root because sudo was used. If the build agent requires non-root ownership, run 'sudo chown -R <user>:<group> /usr/local/swift-*' as needed.
exit 0
