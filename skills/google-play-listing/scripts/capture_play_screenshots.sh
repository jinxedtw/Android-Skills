#!/usr/bin/env bash
# Capture a PNG screenshot from a connected Android device via adb.
# Usage:
#   ./capture_play_screenshots.sh /path/to/out.png [serial]
# Exit codes:
#   2 adb missing
#   3 unauthorized
#   4 no device
#   5 multiple devices and no serial
#   6 pull failed

set -euo pipefail

OUT_FILE="${1:-}"
SERIAL="${2:-}"

if [[ -z "$OUT_FILE" ]]; then
  echo "Usage: $0 /path/to/out.png [serial]" >&2
  exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found on PATH." >&2
  exit 2
fi

adb_cmd() {
  if [[ -n "$SERIAL" ]]; then
    adb -s "$SERIAL" "$@"
  else
    adb "$@"
  fi
}

mapfile -t lines < <(adb devices | tail -n +2)
ready=()
while IFS= read -r line; do
  [[ -z "${line// }" ]] && continue
  serial=$(awk '{print $1}' <<<"$line")
  state=$(awk '{print $2}' <<<"$line")
  if [[ "$state" == "unauthorized" ]]; then
    echo "Device $serial is unauthorized. Ask the user to accept the RSA prompt." >&2
    exit 3
  fi
  if [[ "$state" == "device" ]]; then
    ready+=("$serial")
  fi
done < <(adb devices | tail -n +2)

if [[ ${#ready[@]} -eq 0 ]]; then
  echo "No adb device in 'device' state. Ask the user to connect a phone." >&2
  exit 4
fi

if [[ -z "$SERIAL" && ${#ready[@]} -gt 1 ]]; then
  echo "Multiple devices: ${ready[*]}. Pass serial as \$2." >&2
  exit 5
fi

mkdir -p "$(dirname "$OUT_FILE")"
remote="/sdcard/Download/play_cap_${RANDOM}.png"
cleanup() { adb_cmd shell rm -f "$remote" >/dev/null 2>&1 || true; }
trap cleanup EXIT

adb_cmd shell screencap -p "$remote"
adb_cmd pull "$remote" "$OUT_FILE" >/dev/null

if [[ ! -f "$OUT_FILE" ]]; then
  echo "Screenshot was not written to $OUT_FILE" >&2
  exit 6
fi

echo "Saved $OUT_FILE"
