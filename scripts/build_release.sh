#!/bin/bash
# MyCosmetics Production Build Script
# Builds Android AAB + iOS IPA for App Store submission

set -euo pipefail

echo "=== MyCosmetics Release Build ==="
APP_DIR="$(cd "$(dirname "$0")/../mycosmetics_flutter" && pwd)"
cd "$APP_DIR"

# Verify environment
flutter --version
dart --version

echo "[1/6] Cleaning previous build..."
flutter clean

echo "[2/6] Installing dependencies..."
flutter pub get

echo "[3/6] Running tests..."
flutter test

echo "[4/6] Analyzing code..."
flutter analyze --fatal-warnings

echo "[5/6] Building Android App Bundle..."
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android \
  --dart-define=API_BASE_URL=https://api.mycosmetics.app/ \
  --dart-define=ENV=production

echo "[6/6] Building iOS..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  flutter build ipa \
    --release \
    --obfuscate \
    --split-debug-info=build/debug-info/ios \
    --dart-define=API_BASE_URL=https://api.mycosmetics.app/ \
    --dart-define=ENV=production
  echo "iOS IPA: build/ios/ipa/"
else
  echo "iOS build skipped (requires macOS)"
fi

echo ""
echo "=== Build Complete ==="
echo "Android AAB: build/app/outputs/bundle/release/app-release.aab"
echo "Upload AAB to Google Play Console"
echo "Upload IPA to App Store Connect via Transporter"
