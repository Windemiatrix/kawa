#!/usr/bin/env bash
# changelog-extract.sh - print the CHANGELOG.md section body for a version.
#
# Section body is everything after the heading '## X.Y.Z (date)' up to
# (but not including) the next '## ' heading, with surrounding blank lines
# trimmed. Fails fast (before tagging) if the section is missing or empty.
#
# Usage: changelog-extract.sh X.Y.Z
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") X.Y.Z" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

version="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/.."
CHANGELOG="${REPO_ROOT}/CHANGELOG.md"

if [[ ! -f "${CHANGELOG}" ]]; then
  echo "FAIL: ${CHANGELOG} not found" >&2
  exit 1
fi

found=0
lines=()

while IFS= read -r line || [[ -n "${line}" ]]; do
  if [[ "${found}" -eq 1 ]]; then
    case "${line}" in
      "## "*) break ;;
    esac
    lines+=("${line}")
  else
    case "${line}" in
      "## ${version}" | "## ${version} "*) found=1 ;;
    esac
  fi
done < "${CHANGELOG}"

if [[ "${found}" -eq 0 ]]; then
  echo "FAIL: no changelog section found for version ${version}" >&2
  exit 1
fi

# Trim leading blank lines.
start=0
while [[ "${start}" -lt "${#lines[@]}" && -z "${lines[${start}]}" ]]; do
  start=$((start + 1))
done

# Trim trailing blank lines.
end=$((${#lines[@]} - 1))
while [[ "${end}" -ge "${start}" && -z "${lines[${end}]}" ]]; do
  end=$((end - 1))
done

if [[ "${end}" -lt "${start}" ]]; then
  echo "FAIL: changelog section for version ${version} is empty" >&2
  exit 1
fi

for ((i = start; i <= end; i++)); do
  printf '%s\n' "${lines[${i}]}"
done
