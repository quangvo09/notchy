#!/bin/bash

# Script to kill current Notchy app, build release standalone app, and run it

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

echo ""
echo "🏗️ Building Notchy in release mode..."

# Build the release version using swift build
swift build -c release

# Check if build was successful
if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

EXECUTABLE_PATH="./.build/release/Notchy"

if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo "❌ Could not find built executable"
    exit 1
fi

echo ""
echo "📦 Creating standalone app bundle..."

# Remove old app if exists
rm -rf ./Notchy.app

# Create app bundle structure
mkdir -p ./Notchy.app/Contents/MacOS
mkdir -p ./Notchy.app/Contents/Resources

# Create Info.plist
cat > ./Notchy.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Notchy</string>
    <key>CFBundleIdentifier</key>
    <string>com.notchyapp.notchy</string>
    <key>CFBundleName</key>
    <string>Notchy</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Copy executable
cp "$EXECUTABLE_PATH" ./Notchy.app/Contents/MacOS/

# Copy resources if they exist
if [ -d "Notchy/Resources" ]; then
    cp -R Notchy/Resources/* ./Notchy.app/Contents/Resources/
fi

echo ""
echo "🚀 Running Notchy standalone app..."

# Run the app
open ./Notchy.app

echo ""
echo "✨ Done! Notchy is now running as a standalone app."