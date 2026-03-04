#!/usr/bin/env bash
# Shared utility functions for sprite-env scripts

set -euo pipefail

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

_color_reset="\033[0m"
_color_green="\033[0;32m"
_color_yellow="\033[0;33m"
_color_red="\033[0;31m"
_color_cyan="\033[0;36m"

info()  { echo -e "${_color_green}[info]${_color_reset}  $*"; }
warn()  { echo -e "${_color_yellow}[warn]${_color_reset}  $*"; }
error() { echo -e "${_color_red}[error]${_color_reset} $*" >&2; }
step()  { echo -e "${_color_cyan}[step]${_color_reset}  $*"; }

# ---------------------------------------------------------------------------
# Guards / helpers
# ---------------------------------------------------------------------------

is_installed() {
  command -v "$1" &>/dev/null
}

ensure_dir() {
  [[ -d "$1" ]] || mkdir -p "$1"
}

# ---------------------------------------------------------------------------
# TOML config reader (flat key = "value" format)
# ---------------------------------------------------------------------------

# Usage: toml_get <file> <key>
# Returns the value for a key, stripping surrounding quotes.
toml_get() {
  local file="$1" key="$2"
  grep -E "^${key}\s*=" "$file" 2>/dev/null \
    | head -1 \
    | sed 's/^[^=]*=\s*//' \
    | sed 's/^["'\'']\(.*\)["'\'']\s*$/\1/'
}

# Usage: toml_get_bool <file> <key>
# Returns 0 (true) if value is "true", 1 otherwise.
toml_get_bool() {
  local val
  val="$(toml_get "$1" "$2")"
  [[ "${val,,}" == "true" ]]
}

# ---------------------------------------------------------------------------
# Paths & defaults
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." 2>/dev/null && pwd || echo "$SCRIPT_DIR")"
CONFIG_FILE="${SPRITE_ENV_CONFIG:-${REPO_DIR}/config.toml}"
APP_DIR="${APP_DIR:-$(toml_get "$CONFIG_FILE" "app_dir" 2>/dev/null || echo "$HOME/Code/savvycal/appointments-app")}"
