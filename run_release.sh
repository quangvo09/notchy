#!/bin/bash

# Script to build release standalone app bundle

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

# Create Info.plist with proper permissions
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
    <key>CFBundleDisplayName</key>
    <string>Notchy</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Notchy needs Bluetooth access to monitor AirPods connection and battery status.</string>
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>Notchy uses Bluetooth to display AirPods battery information in the notch.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
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