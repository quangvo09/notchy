#!/bin/bash

# Script to build, sign, and install Notchy.app properly

echo "🔍 Looking for running Notchy processes..."

# Kill any running Notchy processes
if pgrep -f "Notchy" > /dev/null; then
    echo "⚡ Found running Notchy processes. Terminating..."
    pkill -f "Notchy"
    sleep 2
    # Force kill if still running
    if pgrep -f "Notchy" > /dev/null; then
        echo "💥 Force killing Notchy processes..."
        pkill -9 -f "Notchy"
        sleep 1
    fi
else
    echo "✅ No Notchy processes found running"
fi

# echo ""
# echo "🏗️ Building Notchy for release..."
# swift build -c release

# if [ $? -ne 0 ]; then
#     echo "❌ Build failed!"
#     exit 1
# fi

# echo "📦 Creating app bundle..."
# ./run_release.sh

# echo ""
# echo "🔐 Requesting code signing (optional)..."
# # Try to sign with ad-hoc signature if available
# codesign --force --deep --sign - ./Notchy.app 2>/dev/null || echo "   (Skipping code signing - not required for personal use)"

# echo ""
# echo "📁 Installing to Applications folder..."

# # Create user Applications directory if it doesn't exist
# mkdir -p ~/Applications

# # Remove old app if exists
# rm -rf ~/Applications/Notchy.app

# # Copy app to user Applications (no sudo needed)
# cp -R ./Notchy.app ~/Applications/

# echo ""
# echo "✅ App installed to ~/Applications/Notchy.app"
# echo ""
# echo "📋 To grant Bluetooth permissions:"
# echo "   1. Open System Settings > Privacy & Security > Bluetooth"
# echo "   2. Find Notchy in the list and click the '+' to add it"
# echo "   3. Enable Bluetooth permission for Notchy"
# echo ""
# echo "   Note: The first time you run Notchy, macOS will ask for Bluetooth permission"
# echo ""
# echo "🚀 Launching Notchy..."
# open ~/Applications/Notchy.app

# echo ""
# echo "✨ Done! Notchy is now installed and running."
# echo "   Check the notch area for the app!"