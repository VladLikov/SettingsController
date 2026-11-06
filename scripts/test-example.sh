#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# MODE=all (default) builds and tests on one simulator.
# MODE=build compiles once for any simulator (build-for-testing); MODE=test runs those products
# with test-without-building, so CI compiles once and tests on several devices.
# MODE=boot only starts booting the selected simulator, so CI can overlap a first boot with downloads.
MODE=${MODE:-all}
case "$MODE" in all|build|test|boot) ;; *) echo 'MODE must be all, build, test or boot' >&2; exit 2;; esac
DERIVED=.build/example-derived
BUILD_FLAGS=(CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0)
if [ "$MODE" = build ]; then
  mkdir -p .build/example-results
  python3 scripts/generate-example.py
  xcodebuild -project Examples/SettingsExample/SettingsExample.xcodeproj -scheme SettingsExample \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$DERIVED" \
    build-for-testing "${BUILD_FLAGS[@]}" 2>&1 | tee .build/example-results/build.log
  exit 0
fi
DEVICE_FAMILY=${DEVICE_FAMILY:-iPhone}
case "$DEVICE_FAMILY" in iPhone|iPad) ;; *) exit 2;; esac
RUNTIME=${IOS_RUNTIME:-$(xcrun --sdk iphonesimulator --show-sdk-version)}
OUT=".build/example-results/${RESULT_LABEL:-$DEVICE_FAMILY}"
mkdir -p "$OUT"
[ "$MODE" = all ] && python3 scripts/generate-example.py
xcrun simctl list devices available -j > "$OUT/simulators.json"
ID=$(python3 - "$OUT/simulators.json" "$RUNTIME" "$DEVICE_FAMILY" "${DEVICE_NAME:-}" <<'PY'
import json,sys
runtime='com.apple.CoreSimulator.SimRuntime.iOS-'+sys.argv[2].replace('.','-')
devices=sorted((d for d in json.load(open(sys.argv[1]))['devices'].get(runtime,[]) if d.get('isAvailable') and (d['name'] == sys.argv[4] if sys.argv[4] else d['name'].startswith(sys.argv[3]))),key=lambda d:d['name'])
assert devices, 'Missing requested runtime/device: '+runtime+' '+sys.argv[3]
print(devices[0]['udid'])
PY
)
if [ "$MODE" = boot ]; then
  xcrun simctl boot "$ID" 2>&1 || true
  exit 0
fi
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
# Wait for Apple's native boot-readiness monitor before starting UI automation.
# A device can be selected while CoreSimulator is still completing its first boot.
xcrun simctl bootstatus "$ID" -b 2>&1 | tee "$OUT/bootstatus.log"
TEST_FLAGS=(-destination "platform=iOS Simulator,id=$ID" -derivedDataPath "$DERIVED"
  -resultBundlePath "$OUT/TestResults.xcresult" -parallel-testing-enabled NO -collect-test-diagnostics never
  -test-timeouts-enabled YES -maximum-test-execution-time-allowance 300)
# On CI, a test that fails once is run again: a slow runner snapshot passes the second time,
# while a real failure fails both attempts.
if [ "${CI:-}" = true ]; then TEST_FLAGS+=(-retry-tests-on-failure -test-iterations 2); fi
if [ "$MODE" = test ]; then
  XCTESTRUN=$(ls "$DERIVED"/Build/Products/*.xctestrun 2>/dev/null | head -1)
  [ -n "$XCTESTRUN" ] || { echo "No .xctestrun in $DERIVED/Build/Products; run MODE=build first" >&2; exit 2; }
  if xcodebuild test-without-building -xctestrun "$XCTESTRUN" "${TEST_FLAGS[@]}" 2>&1 | tee "$OUT/test.log"; then exit 0; fi
  [ "${CI:-}" = true ] || exit 65
  # A runner snapshot that times out restarts the test process, and xcodebuild then skips its own retry.
  # Up to three such tests run once more on their own; more failures, or a second failure, fail the job.
  FAILED=$(sed -nE "s/^Test Case '-\[([A-Za-z0-9_]+)\.([A-Za-z0-9_]+) ([A-Za-z0-9_]+)\]' failed.*/\1\/\2\/\3/p" "$OUT/test.log" | sort -u)
  COUNT=$(printf '%s' "$FAILED" | grep -c . || true)
  if [ "$COUNT" -eq 0 ] || [ "$COUNT" -gt 3 ]; then exit 65; fi
  echo "Running $COUNT failed test(s) again:"; echo "$FAILED"
  ONLY=(); while read -r t; do ONLY+=("-only-testing:$t"); done <<<"$FAILED"
  mv "$OUT/TestResults.xcresult" "$OUT/TestResults-first.xcresult"
  xcodebuild test-without-building -xctestrun "$XCTESTRUN" "${TEST_FLAGS[@]}" "${ONLY[@]}" 2>&1 | tee "$OUT/test-rerun.log"
else
  xcodebuild -project Examples/SettingsExample/SettingsExample.xcodeproj -scheme SettingsExample \
    "${TEST_FLAGS[@]}" test "${BUILD_FLAGS[@]}" 2>&1 | tee "$OUT/test.log"
fi
