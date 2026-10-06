#!/bin/bash
set -e

# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter is available
flutter --version

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build for web
flutter build web --release

echo "Build completed successfully!"