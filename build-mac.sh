#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
[[ "$(uname -s)" == "Darwin" ]] || { echo "Run on macOS" >&2; exit 1; }
SDK="$(xcrun --sdk macosx --show-sdk-path)"
mkdir -p build dist/ProjectBridge.app/Contents/MacOS dist/ProjectBridge.app/Contents/Resources
ARCH="$(uname -m)"
case "$ARCH" in
  arm64|x86_64) ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac
echo "Building for this Mac ($ARCH)..."
xcrun swiftc -O -parse-as-library -target "${ARCH}-apple-macosx12.0" -sdk "$SDK" \
  Sources/ProjectBridge.swift -o "build/ProjectBridge-${ARCH}"
cp "build/ProjectBridge-${ARCH}" dist/ProjectBridge.app/Contents/MacOS/ProjectBridge
cp Resources/Info.plist dist/ProjectBridge.app/Contents/Info.plist
cp engine_runner.py install_engine.sh dist/ProjectBridge.app/Contents/Resources/
chmod +x dist/ProjectBridge.app/Contents/MacOS/ProjectBridge
echo "Built $(pwd)/dist/ProjectBridge.app"
file dist/ProjectBridge.app/Contents/MacOS/ProjectBridge
