#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
DEVICE_FAMILY=${DEVICE_FAMILY:-iPhone}
case "$DEVICE_FAMILY" in iPhone|iPad) ;; *) echo 'DEVICE_FAMILY must be iPhone or iPad' >&2; exit 2;; esac
RUNTIME=${IOS_RUNTIME:-$(xcrun --sdk iphonesimulator --show-sdk-version)}
RESULTS=".build/verification/${RESULT_LABEL:-$DEVICE_FAMILY}"
mkdir -p "$RESULTS"
xcodebuild -version | tee "$RESULTS/toolchain.txt"
xcrun swift --version | tee -a "$RESULTS/toolchain.txt"
xcrun simctl list devices available -j > "$RESULTS/simulators.json"
DEVICE_ID=$(python3 - "$RESULTS/simulators.json" "$RUNTIME" "$DEVICE_FAMILY" "${DEVICE_NAME:-}" <<'PY'
import json, sys
runtime = 'com.apple.CoreSimulator.SimRuntime.iOS-' + sys.argv[2].replace('.', '-')
devices = json.load(open(sys.argv[1]))['devices'].get(runtime, [])
devices = sorted((d for d in devices if d.get('isAvailable') and (d['name'] == sys.argv[4] if sys.argv[4] else d['name'].startswith(sys.argv[3]))), key=lambda d: d['name'])
if not devices:
    raise SystemExit('Missing requested simulator runtime/device: ' + runtime + ' ' + sys.argv[3])
print(devices[0]['udid'])
PY
)
printf 'Runtime=%s\nDevice=%s\n' "$RUNTIME" "$DEVICE_ID" | tee "$RESULTS/destination.txt"
git rev-parse HEAD > "$RESULTS/tested-sha.txt"
# Delete only this script's previous result bundle, never a source/build directory.
rm -rf "$RESULTS/TestResults.xcresult"
summarize() {
    if [ -d "$RESULTS/TestResults.xcresult" ]; then
        xcrun xcresulttool get test-results summary --path "$RESULTS/TestResults.xcresult" > "$RESULTS/summary.json" || true
        cat "$RESULTS/summary.json"
    fi
}
trap summarize EXIT
xcodebuild -resolvePackageDependencies -scheme SettingsController
xcodebuild -scheme SettingsController \
    -destination "platform=iOS Simulator,id=$DEVICE_ID" \
    -derivedDataPath .build/xcode \
    -resultBundlePath "$RESULTS/TestResults.xcresult" \
    -parallel-testing-enabled NO -collect-test-diagnostics never -test-timeouts-enabled YES \
    -maximum-test-execution-time-allowance 60 \
    test CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 \
    2>&1 | tee "$RESULTS/test.log"
