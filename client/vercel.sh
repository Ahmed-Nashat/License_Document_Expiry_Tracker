#!/bin/bash
set -euo pipefail

if [[ -z "${API_BASE_URL:-}" && -n "${RENDER_API_URL:-}" ]]; then
  API_BASE_URL="${RENDER_API_URL%/}"
fi

if [[ -z "${API_BASE_URL:-}" ]]; then
  : "${VERCEL_URL:?API_BASE_URL must be set locally; Vercel supplies VERCEL_URL during deployment}"
  API_BASE_URL="https://${VERCEL_URL}"
fi

echo "Installing Flutter for Vercel..."
git clone --depth 1 --branch 3.29.3 https://github.com/flutter/flutter.git
export PATH="$PWD/flutter/bin:$PATH"
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"
