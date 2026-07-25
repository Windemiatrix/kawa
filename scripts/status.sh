#!/usr/bin/env bash
# status.sh - compare kawa versions across info.plist, the latest GitHub
# release, and the Homebrew cask.
#
# Reads the pipeline in order: kawa/Info.plist (source of truth, via
# scripts/version.sh), the latest GitHub release tag, and the version
# pinned in Windemiatrix/homebrew-tap's Casks/kawa.rb. A published release
# is never rolled back on a failed cask bump, so any lag must show up here.
#
# A network failure or a repo with no releases yet degrades the affected
# value to "unavailable", reported as such rather than as a version lag.
#
# Usage: status.sh
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0")" >&2
  exit 1
}

[[ $# -eq 0 ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GITHUB_RELEASE_URL="https://api.github.com/repos/Windemiatrix/kawa/releases/latest"
# HEAD resolves to the tap's default branch, whatever it is named.
CASK_RAW_URL="https://raw.githubusercontent.com/Windemiatrix/homebrew-tap/HEAD/Casks/kawa.rb"

# version_lt A B - true (exit 0) if semver A is numerically less than B.
# A missing component compares as 0 (e.g. "1.2" vs "1.2.0").
version_lt() {
  local a="$1" b="$2"
  local a_parts=() b_parts=()
  IFS='.' read -ra a_parts <<< "${a}"
  IFS='.' read -ra b_parts <<< "${b}"
  local i an bn
  for i in 0 1 2; do
    an="${a_parts[i]:-0}"
    bn="${b_parts[i]:-0}"
    if [[ "${an}" -lt "${bn}" ]]; then
      return 0
    elif [[ "${an}" -gt "${bn}" ]]; then
      return 1
    fi
  done
  return 1
}

local_version="$("${SCRIPT_DIR}/version.sh")"

github_json="$(curl -fsS "${GITHUB_RELEASE_URL}" 2>/dev/null)" || github_json=""
github_tag="unavailable"
if [[ -n "${github_json}" ]]; then
  github_tag="$(printf '%s\n' "${github_json}" |
    sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  github_tag="${github_tag%%$'\n'*}"
  github_tag="${github_tag#v}"
  [[ -n "${github_tag}" ]] || github_tag="unavailable"
fi

cask_content="$(curl -fsS "${CASK_RAW_URL}" 2>/dev/null)" || cask_content=""
cask_version="unavailable"
if [[ -n "${cask_content}" ]]; then
  cask_version="$(printf '%s\n' "${cask_content}" |
    sed -n 's/^[[:space:]]*version "\([^"]*\)".*/\1/p')"
  cask_version="${cask_version%%$'\n'*}"
  [[ -n "${cask_version}" ]] || cask_version="unavailable"
fi

printf '%-17s%s\n' "info.plist:" "${local_version}"
printf '%-17s%s\n' "github release:" "${github_tag}"
printf '%-17s%s\n' "cask:" "${cask_version}"

warnings=()

if [[ "${github_tag}" == "unavailable" ]]; then
  warnings+=("github release unavailable")
elif [[ "${local_version}" != "${github_tag}" ]]; then
  if version_lt "${github_tag}" "${local_version}"; then
    warnings+=("github release (${github_tag}) lags behind info.plist (${local_version})")
  else
    warnings+=("info.plist (${local_version}) lags behind github release (${github_tag})")
  fi
fi

if [[ "${cask_version}" == "unavailable" ]]; then
  warnings+=("cask unavailable")
elif [[ "${github_tag}" != "unavailable" && "${github_tag}" != "${cask_version}" ]]; then
  if version_lt "${cask_version}" "${github_tag}"; then
    warnings+=("cask (${cask_version}) lags behind github release (${github_tag})")
  else
    warnings+=("github release (${github_tag}) lags behind cask (${cask_version})")
  fi
fi

if [[ "${#warnings[@]}" -eq 0 ]]; then
  echo "OK: versions in sync"
  exit 0
fi

joined="${warnings[0]}"
for ((i = 1; i < ${#warnings[@]}; i++)); do
  joined="${joined}; ${warnings[i]}"
done
echo "Warning: ${joined}"
exit 1
