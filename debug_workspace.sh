#!/bin/bash

# Notchy Debug Helper
# Quick commands for debugging and development

echo "🔍 Notchy Debug Helper"
echo ""

# Check if Notchy is running
if pgrep -x "Notchy" > /dev/null; then
    echo "✅ Notchy is running (PID: $(pgrep -x Notchy))"
    echo "   CPU: $(ps aux | grep [N]otchy | awk '{print $3}')%"
    echo "   Memory: $(ps aux | grep [N]otchy | awk '{print $4}')%"
else
    echo "❌ Notchy is not running"
fi

echo ""
echo "Available commands:"
echo "  1. Kill Notchy:       killall Notchy"
echo "  2. View logs:         log show --predicate 'process == \"Notchy\"' --last 1m"
echo "  3. Build:             ./build_and_run.sh"
echo "  4. Open project:      open Notchy/Notchy.xcodeproj"
echo "  5. Clean build:       xcodebuild clean -project Notchy/Notchy.xcodeproj"
echo ""

# Check DerivedData
if [ -d ~/Library/Developer/Xcode/DerivedData/Notchy-* ]; then
    echo "📦 DerivedData location:"
    ls -d ~/Library/Developer/Xcode/DerivedData/Notchy-*
fi
