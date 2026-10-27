#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE_FAMILY=${DEVICE_FAMILY:-iPhone}
case "$DEVICE_FAMILY" in iPhone|iPad) ;; *) exit 2;; esac
RUNTIME=${IOS_RUNTIME:-$(xcrun --sdk iphonesimulator --show-sdk-version)}
OUT=".build/example-results/$DEVICE_FAMILY"
mkdir -p "$OUT"
python3 scripts/generate-example.py
xcrun simctl list devices available -j > "$OUT/simulators.json"
ID=$(python3 - "$OUT/simulators.json" "$RUNTIME" "$DEVICE_FAMILY" <<'PY'
import json,sys
runtime='com.apple.CoreSimulator.SimRuntime.iOS-'+sys.argv[2].replace('.','-')
devices=sorted((d for d in json.load(open(sys.argv[1]))['devices'].get(runtime,[]) if d.get('isAvailable') and d['name'].startswith(sys.argv[3])),key=lambda d:d['name'])
assert devices, 'Missing requested runtime/device: '+runtime+' '+sys.argv[3]
print(devices[0]['udid'])
PY
)
git rev-parse HEAD > "$OUT/tested-sha.txt"
printf 'Runtime=%s\nDevice=%s\n' "$RUNTIME" "$ID" > "$OUT/destination.txt"
rm -rf "$OUT/TestResults.xcresult"
collect() {
  if [ -d "$OUT/TestResults.xcresult" ]; then
    xcrun xcresulttool get test-results summary --path "$OUT/TestResults.xcresult" > "$OUT/summary.json" || true
    xcrun xcresulttool export attachments --path "$OUT/TestResults.xcresult" --output-path "$OUT/attachments" || true
    cat "$OUT/summary.json"
  fi
}
trap collect EXIT
xcodebuild -project Examples/SettingsExample/SettingsExample.xcodeproj -scheme SettingsExample \
  -destination "platform=iOS Simulator,id=$ID" -derivedDataPath .build/example-derived \
  -resultBundlePath "$OUT/TestResults.xcresult" -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -maximum-test-execution-time-allowance 120 \
  test CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 2>&1 | tee "$OUT/test.log"
