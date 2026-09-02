#!/bin/bash
set -euo pipefail

: "${API_BASE_URL:?API_BASE_URL must be set to the public HTTPS API URL}"

echo "Installing Flutter for Vercel..."
git clone --depth 1 --branch 3.29.3 https://github.com/flutter/flutter.git
export PATH="$PWD/flutter/bin:$PATH"
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"
