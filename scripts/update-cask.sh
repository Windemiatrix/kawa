#!/usr/bin/env bash
# update-cask.sh - update version and sha256 in a Homebrew cask file.
#
# Edits <tap-dir>/Casks/kawa.rb in place, portably (sed to a temp file + mv,
# no 'sed -i'): the line matching leading whitespace + 'version "..."' gets
# the new version, and the 'sha256 "..."' line gets the new digest.
#
# No git operations here - commit/push of the tap repo live in the GitHub
# workflow, not in this script.
#
# Usage: update-cask.sh <version> <sha256> <tap-checkout-dir>
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <version> <sha256> <tap-checkout-dir>" >&2
  exit 1
}

[[ $# -eq 3 ]] || usage

version="$1"
sha256="$2"
tap_dir="$3"

# Keep the ERE pattern in a variable (bash 3.2 quirk: an inline literal
# passed to [[ =~ ]] can be parsed differently depending on quoting).
version_re='^[0-9]+\.[0-9]+\.[0-9]+$'
sha256_re='^[0-9a-f]{64}$'

if [[ ! "${version}" =~ ${version_re} ]]; then
  echo "FAIL: version '${version}' is not in X.Y.Z format" >&2
  exit 1
fi

if [[ ! "${sha256}" =~ ${sha256_re} ]]; then
  echo "FAIL: sha256 '${sha256}' is not a 64-character lowercase hex digest" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_file="${SCRIPT_DIR}/cask-template.rb"

cask_file="${tap_dir}/Casks/kawa.rb"

if [[ ! -f "${cask_file}" ]]; then
  echo "Info: bootstrapping Casks/kawa.rb from template"
  mkdir -p "${tap_dir}/Casks"
  cp "${template_file}" "${cask_file}"
fi

tmp_file="$(mktemp "${cask_file}.XXXXXX")"
cleanup() { rm -f "${tmp_file}"; }
trap cleanup EXIT INT TERM

sed -e "s/^\([[:space:]]*\)version \"[^\"]*\"/\1version \"${version}\"/" \
    -e "s/^\([[:space:]]*\)sha256 \"[^\"]*\"/\1sha256 \"${sha256}\"/" \
    "${cask_file}" > "${tmp_file}"

mv "${tmp_file}" "${cask_file}"

if ! grep -qF "version \"${version}\"" "${cask_file}"; then
  echo "FAIL: version was not updated in ${cask_file}" >&2
  exit 1
fi

if ! grep -qF "sha256 \"${sha256}\"" "${cask_file}"; then
  echo "FAIL: sha256 was not updated in ${cask_file}" >&2
  exit 1
fi

echo "OK: ${cask_file} updated to version ${version}"
