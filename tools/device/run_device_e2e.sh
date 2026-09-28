#!/usr/bin/env bash
# Runs MemoX's DEVICE-E2E scenarios (FE-D3) on one Android device or emulator.
#
#   tools/device/run_device_e2e.sh [-d DEVICE] all | ID...
#
# IDs: IT-PLAT-001 IT-PLAT-002 IT-PLAT-003 IT-PLAT-004 IT-PLAT-005
#      IT-PLAT-006 IT-CONT-008 IT-NAV-007
#
# Each scenario clears the app's data first. Phases are integration tests
# under integration_test/, run with `flutter test --no-uninstall` so the data
# survives from one phase to the next; the tool force-stops the app after
# each, the process death a restart needs. A phase talks to this script with
# `MEMOX-E2E:` lines (spec D3). Spec:
# docs/superpowers/specs/2026-09-28-device-e2e-design.md.
set -uo pipefail
export MSYS_NO_PATHCONV=1

readonly PKG=com.memox.memox
readonly MARK='MEMOX-E2E:'
readonly ALL=(IT-PLAT-001 IT-PLAT-002 IT-PLAT-003 IT-PLAT-004 IT-PLAT-005
  IT-CONT-008 IT-NAV-007 IT-PLAT-006)
readonly UI_TIMEOUT_S=40

cd "$(dirname "$0")/../.." || exit 2

die() { echo "error: $*" >&2; exit 2; }

find_adb() {
  if command -v adb >/dev/null 2>&1; then echo adb; return; fi
  local sdk
  for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" \
    "${LOCALAPPDATA:-}/Android/sdk" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
    [[ -n "$sdk" ]] || continue
    for exe in "$sdk/platform-tools/adb" "$sdk/platform-tools/adb.exe"; do
      if [[ -x "$exe" ]]; then echo "$exe"; return; fi
    done
  done
  die "adb not found; put platform-tools on PATH or set ANDROID_HOME"
}

ADB=$(find_adb)
DEVICE=""
while getopts "d:" opt; do
  case $opt in
    d) DEVICE=$OPTARG ;;
    *) die "usage: $0 [-d DEVICE] all | ID..." ;;
  esac
done
shift $((OPTIND - 1))
[[ $# -gt 0 ]] || die "usage: $0 [-d DEVICE] all | ID..."
command -v flutter >/dev/null 2>&1 || die "flutter not found on PATH"

if [[ -z "$DEVICE" ]]; then
  mapfile -t attached < <("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  [[ ${#attached[@]} -eq 1 ]] || die "attach exactly one device, or pass -d (found ${#attached[@]})"
  DEVICE=${attached[0]}
fi

# Kotlin's incremental compile fails when the pub cache and the repo sit on
# different drives (Windows); a full compile of the plugins costs seconds.
flutter_() { GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.project.kotlin.incremental=false" flutter "$@"; }
adbs() { "$ADB" -s "$DEVICE" "$@"; }
sh_() { adbs shell "$@" | tr -d '\r'; }

STATE=$(mktemp -d)
FAILED_AT=""

offline_off() { sh_ cmd connectivity airplane-mode disable >/dev/null 2>&1 || true; }
cleanup() { offline_off; rm -rf "$STATE"; }
trap cleanup EXIT
trap 'echo "interrupted" >&2; exit 130' INT TERM

offline_on() {
  sh_ cmd connectivity airplane-mode enable >/dev/null ||
    { FAILED_AT="airplane mode"; return 1; }
}

installed() { sh_ pm list packages "$PKG" | grep -qx "package:$PKG"; }

# The scenario's clean start: no app data, no values from an earlier one.
reset_app() {
  rm -f "$STATE"/*
  if installed; then sh_ pm clear "$PKG" >/dev/null; fi
}

# English for this script's own screen checks (spec D7).
english() { sh_ cmd locale set-app-locales "$PKG" --locales en-US >/dev/null 2>&1 || true; }

# One phase: integration_test/<name>_test.dart. Values signalled by earlier
# phases come back as --dart-define=MEMOX_E2E_<KEY>=<VALUE>.
phase() {
  local name=$1 defines=() key line
  for key in "$STATE"/*; do
    [[ -e "$key" ]] || continue
    defines+=("--dart-define=MEMOX_E2E_$(basename "$key")=$(cat "$key")")
  done
  echo "-- phase $name"
  # flutter test finds the app's VM service in logcat; an earlier phase's
  # line there, or its port forward, would send it to a dead service.
  adbs logcat -c
  adbs forward --remove-all
  flutter_ test "integration_test/${name}_test.dart" -d "$DEVICE" --no-uninstall \
    "${defines[@]}" 2>&1 |
    while IFS= read -r line; do
      echo "$line"
      case $line in
        *"$MARK back"*) sh_ input keyevent KEYCODE_BACK >/dev/null ;;
        *"$MARK snap"*)
          mkdir -p build/device_e2e
          adbs exec-out screencap -p >"build/device_e2e/$name.png"
          echo "screenshot: build/device_e2e/$name.png" ;;
        *"$MARK value "*)
          line=${line#*"$MARK value "}
          printf '%s' "${line#*=}" >"$STATE/${line%%=*}" ;;
      esac
    done
  [[ ${PIPESTATUS[0]} -eq 0 ]] || { FAILED_AT="phase $name"; return 1; }
}

# Waits until the screen shows [text], through a uiautomator dump.
expect_text() {
  local text=$1 end=$((SECONDS + UI_TIMEOUT_S))
  while ((SECONDS < end)); do
    sh_ uiautomator dump /sdcard/memox_e2e.xml >/dev/null 2>&1
    if adbs exec-out cat /sdcard/memox_e2e.xml | grep -qF -- "$text"; then return 0; fi
    sleep 2
  done
  FAILED_AT="screen never showed \"$text\""
  return 1
}

deeplink() { sh_ am start -W -a android.intent.action.VIEW -d "$1" "$PKG" >/dev/null; }
stop_app() { sh_ am force-stop "$PKG"; }

scenario_IT-PLAT-001() { reset_app && phase it_plat_001_cold_start; }

scenario_IT-PLAT-002() {
  reset_app && phase it_plat_002_a_build_tree && phase it_plat_002_b_after_restart
}

scenario_IT-NAV-007() {
  reset_app && offline_on &&
    phase it_nav_007_a_offline_content && phase it_nav_007_b_after_restart
  local status=$?
  offline_off
  return $status
}

scenario_IT-PLAT-004() {
  reset_app && phase it_plat_004_a_seed_deck || return 1
  local deck
  deck=$(cat "$STATE/DECK_ID" 2>/dev/null) || { FAILED_AT="no DECK_ID signalled"; return 1; }
  # The phase left its test build installed; the OS must open the app itself.
  # install -r keeps the data.
  echo "-- installing the app over the test build"
  flutter_ build apk --debug >/dev/null &&
    adbs install -r build/app/outputs/flutter-apk/app-debug.apk >/dev/null ||
    { FAILED_AT="installing the app"; return 1; }
  english
  stop_app && deeplink "memox://app/decks/deck/$deck" && expect_text "D-EB" &&
    sh_ input keyevent KEYCODE_BACK && expect_text "1 deck" &&
    stop_app && deeplink "memox://app/decks/deck/missing" &&
    expect_text "This deck is no longer here" &&
    stop_app && deeplink "memox://app/nowhere" && expect_text "Page not found"
}

scenario_IT-PLAT-003() {
  reset_app && phase it_plat_003_a_start_session && phase it_plat_003_b_resume
}

scenario_IT-PLAT-005() { reset_app && phase it_plat_005_system_back; }

scenario_IT-CONT-008() {
  reset_app && offline_on &&
    phase it_cont_008_a_offline_session && phase it_cont_008_b_after_restart
  local status=$?
  offline_off
  return $status
}

# A release build installs on a cleared device, starts from the launcher
# intent and shows its first screen, with no crash in logcat (spec D6).
scenario_IT-PLAT-006() {
  local apk=build/app/outputs/flutter-apk/app-release.apk
  echo "-- building the release APK"
  flutter_ build apk --release >/dev/null || { FAILED_AT="release build"; return 1; }
  if installed; then adbs uninstall "$PKG" >/dev/null; fi
  adbs install "$apk" >/dev/null || { FAILED_AT="install"; return 1; }
  english
  adbs logcat -c
  sh_ monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1
  expect_text "Start your library" || return 1
  if adbs logcat -d | grep -E "FATAL EXCEPTION|E/flutter"; then
    FAILED_AT="a crash in logcat"
    return 1
  fi
  adbs uninstall "$PKG" >/dev/null
}

ids=("$@")
[[ ${ids[0]} == all ]] && ids=("${ALL[@]}")
results=()
failures=0
for id in "${ids[@]}"; do
  declare -F "scenario_$id" >/dev/null || die "unknown scenario $id"
  echo "== $id on $DEVICE"
  FAILED_AT=""
  if "scenario_$id"; then
    results+=("PASS $id")
  else
    results+=("FAIL $id (${FAILED_AT:-see the output above})")
    failures=$((failures + 1))
  fi
done

echo "== summary"
printf '%s\n' "${results[@]}"
[[ $failures -eq 0 ]]
