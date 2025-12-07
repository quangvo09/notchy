#!/bin/bash

# Script to build, sign, and install Notchy.app properly
# Usage: ./install_app.sh [--build] [--sign] [--install] [--launch]

# Default behavior: just kill existing processes
BUILD=false
SIGN=false
INSTALL=false
LAUNCH=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            BUILD=true
            shift
            ;;
        --sign)
            SIGN=true
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --launch)
            LAUNCH=true
            shift
            ;;
        --all)
            BUILD=true
            SIGN=true
            INSTALL=true
            LAUNCH=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --build     Build the app using swift build"
            echo "  --sign      Code sign the app (ad-hoc if no certificate)"
            echo "  --install   Install app to ~/Applications"
            echo "  --launch    Launch the app after installation"
            echo "  --all       Perform all steps (build, sign, install, launch)"
            echo "  -h, --help  Show this help message"
            echo ""
            echo "Default behavior: Only kills existing processes"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

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

if [ "$BUILD" = true ]; then
    echo ""
    echo "🏗️ Building Notchy for release..."
    swift build -c release

    if [ $? -ne 0 ]; then
        echo "❌ Build failed!"
        exit 1
    fi

    echo "📦 Creating app bundle..."
    ./run_release.sh

    if [ $? -ne 0 ]; then
        echo "❌ App bundle creation failed!"
        exit 1
    fi
fi

if [ "$SIGN" = true ]; then
    echo ""
    echo "🔐 Requesting code signing (optional)..."
    # Try to sign with ad-hoc signature if available
    codesign --force --deep --sign - ./Notchy.app 2>/dev/null || echo "   (Skipping code signing - not required for personal use)"
fi

if [ "$INSTALL" = true ]; then
    echo ""
    echo "📁 Installing to Applications folder..."

    # Create user Applications directory if it doesn't exist
    mkdir -p ~/Applications

    # Remove old app if exists
    rm -rf ~/Applications/Notchy.app

    # Copy app to user Applications (no sudo needed)
    cp -R ./Notchy.app ~/Applications/

    echo "✅ App installed to ~/Applications/Notchy.app"
    echo ""
    echo "📋 To grant Bluetooth permissions:"
    echo "   1. Open System Settings > Privacy & Security > Bluetooth"
    echo "   2. Find Notchy in the list and click the '+' to add it"
    echo "   3. Enable Bluetooth permission for Notchy"
    echo ""
    echo "   Note: The first time you run Notchy, macOS will ask for Bluetooth permission"
fi

if [ "$LAUNCH" = true ]; then
    echo ""
    echo "🚀 Launching Notchy..."
    open ~/Applications/Notchy.app

    echo ""
    echo "✨ Done! Notchy is now installed and running."
    echo "   Check the notch area for the app!"
else
    echo ""
    echo "✅ Process cleanup complete."
    if [ "$INSTALL" = false ]; then
        echo ""
        echo "💡 Use --all to perform full installation: $0 --all"
        echo "   Or use --help to see all options: $0 --help"
    fi
fi