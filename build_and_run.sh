#!/bin/bash

# Notchy - Build and Run Script
# This script builds the Notchy app and launches it

set -e

echo "🏗️  Building Notchy..."

# Navigate to project directory
cd Notchy

# Kill any running instances
killall Notchy 2>/dev/null || true

# Build the project
xcodebuild -project Notchy.xcodeproj \
    -scheme Notchy \
    -configuration Debug \
    build \
    -quiet

echo "✅ Build successful!"

# Launch the app
echo "🚀 Launching Notchy..."
open ~/Library/Developer/Xcode/DerivedData/Notchy-*/Build/Products/Debug/Notchy.app

# Wait a moment and show process info
sleep 2

if pgrep -x "Notchy" > /dev/null; then
    echo "✨ Notchy is running!"
    echo ""
    echo "📍 Look for the island at the top of your screen"
    echo "🖱️  Hover over it to see it expand"
    echo "🎛️  Click the menu bar icon (🏝️) to quit"
else
    echo "⚠️  Notchy failed to start"
fi
