#!/bin/bash
export PATH=$PATH:$HOME/Library/Android/sdk/emulator:$HOME/Library/Android/sdk/platform-tools

echo "1. Closing heavy emulators to free up 8GB RAM..."
adb devices 2>/dev/null | grep emulator | cut -f1 | while read line; do adb -s $line emu kill; done
sleep 2
killall qemu-system-aarch64 2>/dev/null
killall qemu-system-x86_64 2>/dev/null
killall dart 2>/dev/null

echo "2. Creating new lightweight AVDs..."
flutter emulators --create --name LightRider
flutter emulators --create --name LightDriver

echo "3. Applying lightweight configurations (1GB RAM, 128MB Heap)..."
for AVD in LightRider LightDriver; do
  CONFIG="$HOME/.android/avd/$AVD.avd/config.ini"
  if [ -f "$CONFIG" ]; then
    sed -i '' 's/^hw.ramSize=.*/hw.ramSize=1024/' "$CONFIG" 2>/dev/null || echo "hw.ramSize=1024" >> "$CONFIG"
    sed -i '' 's/^vm.heapSize=.*/vm.heapSize=128/' "$CONFIG" 2>/dev/null || echo "vm.heapSize=128" >> "$CONFIG"
    # Make sure we don't use high res skins to save GPU memory
    sed -i '' 's/^skin.name=.*/skin.name=720x1280/' "$CONFIG" 2>/dev/null
  fi
done

echo "4. Launching lightweight emulators in background..."
flutter emulators --launch LightRider > /dev/null 2>&1 &
flutter emulators --launch LightDriver > /dev/null 2>&1 &

echo "Setup complete. Emulators are booting."
