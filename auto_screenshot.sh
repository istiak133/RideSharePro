#!/bin/bash
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
mkdir -p /Users/istiakahmed/RideSharePro/screenshots

echo "Auto-screenshot started! It will take a screenshot every 3 seconds."
echo "Use your emulator now. Press Ctrl+C to stop this script manually (or let it run for 3 minutes)."

for i in {1..60}; do
  TIMESTAMP=$(date +"%H-%M-%S")
  adb exec-out screencap -p > "/Users/istiakahmed/RideSharePro/screenshots/screen_$TIMESTAMP.png"
  sleep 3
done
echo "Auto-screenshot finished!"
