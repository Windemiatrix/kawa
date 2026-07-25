#!/usr/bin/env bash
# bump-version.sh - set CFBundleShortVersionString to a new version and
# increment CFBundleVersion (build number) by 1.
#
# macOS-only: requires /usr/libexec/PlistBuddy. Does not touch git.
#
# Usage: bump-version.sh X.Y.Z
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") X.Y.Z" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

new_version="$1"
[[ "${new_version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || usage

PLISTBUDDY=/usr/libexec/PlistBuddy
if [[ ! -x "${PLISTBUDDY}" ]]; then
  echo "FAIL: requires a macOS host (PlistBuddy)" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
PLIST="${REPO_ROOT}/kawa/Info.plist"

if [[ ! -f "${PLIST}" ]]; then
  echo "FAIL: ${PLIST} not found" >&2
  exit 1
fi

old_version="$("${PLISTBUDDY}" -c "Print :CFBundleShortVersionString" "${PLIST}")"
old_build="$("${PLISTBUDDY}" -c "Print :CFBundleVersion" "${PLIST}")"
new_build=$((old_build + 1))

"${PLISTBUDDY}" -c "Set :CFBundleShortVersionString ${new_version}" "${PLIST}"
"${PLISTBUDDY}" -c "Set :CFBundleVersion ${new_build}" "${PLIST}"

echo "${old_version} -> ${new_version}"
