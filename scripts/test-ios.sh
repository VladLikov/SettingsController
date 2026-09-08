#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${SIMULATOR_ID:-}" ]]; then
  SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["devices"]
phones = [d for runtime, devices in runtimes.items() if ".iOS-" in runtime for d in devices if d.get("isAvailable") and d["name"].startswith("iPhone")]
if not phones:
    sys.exit("No available iPhone simulator. Install an iOS runtime in Xcode Settings.")
print(next((d for d in phones if d["state"] == "Booted"), phones[0])["udid"])
')
fi
xcodebuild -resolvePackageDependencies -scheme SettingsController
xcodebuild -scheme SettingsController \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath .build/xcode \
  -parallel-testing-enabled NO test
