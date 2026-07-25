#!/usr/bin/env bash
# version.sh - print CFBundleShortVersionString from kawa/Info.plist.
#
# Works on macOS (via /usr/libexec/PlistBuddy when executable) and on Linux
# (fallback: awk over the raw XML - the value is on the line after the key).
# Prints the bare version (e.g. "1.2.0") to stdout, nothing else.
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0")" >&2
  exit 1
}

[[ $# -eq 0 ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
PLIST="${REPO_ROOT}/kawa/Info.plist"

if [[ ! -f "${PLIST}" ]]; then
  echo "FAIL: ${PLIST} not found" >&2
  exit 1
fi

if [[ -x /usr/libexec/PlistBuddy ]]; then
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PLIST}"
else
  awk '
    /<key>CFBundleShortVersionString<\/key>/ {
      getline
      line = $0
      sub(/^[^<]*<string>/, "", line)
      sub(/<\/string>.*$/, "", line)
      print line
      exit
    }
  ' "${PLIST}"
fi
