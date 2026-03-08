#!/usr/bin/env bash
# Main orchestrator — runs shared and personal setup scripts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/helpers.sh"

APP_DIR="$HOME/app"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <github-repo>

Bootstrap a Sprites.dev VM as a dev environment.

Arguments:
  <github-repo>     GitHub repo to clone (e.g. svycal/appointments-app)

Options:
  --shared-only     Run only shared setup (languages, services, tools)
  --personal-only   Run only personal setup (dotfiles, editor, shell)
  -h, --help        Show this help message
EOF
}

# ---------------------------------------------------------------------------
# Script runners
# ---------------------------------------------------------------------------

run_shared() {
  step "=== Shared setup ==="

  info "Installing tools and system dependencies..."
  bash "${SCRIPT_DIR}/shared/tools.sh"

  info "Installing language runtimes..."
  bash "${SCRIPT_DIR}/shared/languages.sh"

  info "Setting up PostgreSQL..."
  bash "${SCRIPT_DIR}/shared/services.sh"

  info "Configuring Claude Code MCP servers..."
  bash "${SCRIPT_DIR}/shared/claude-code.sh"
}

run_personal() {
  step "=== Personal setup ==="

  info "Setting up dotfiles..."
  bash "${SCRIPT_DIR}/personal/dotfiles.sh"

  info "Setting up editor..."
  bash "${SCRIPT_DIR}/personal/editor.sh"

  info "Setting up shell..."
  bash "${SCRIPT_DIR}/personal/shell.sh"
}

clone_app_repo() {
  if [[ -d "$APP_DIR" ]]; then
    info "App repo already cloned at ${APP_DIR}"
    return 0
  fi

  step "Cloning ${APP_REPO} to ${APP_DIR}..."
  gh repo clone "$APP_REPO" "$APP_DIR"
  info "App repo cloned"
}

run_app_setup() {
  step "=== App setup ==="

  clone_app_repo

  local setup_script
  setup_script="$(toml_get "$CONFIG_FILE" "app_setup_cmd" 2>/dev/null || true)"
  setup_script="${setup_script:-script/sprite-setup}"

  local full_path="${APP_DIR}/${setup_script}"

  if [[ ! -x "$full_path" ]]; then
    warn "App setup script not found at ${full_path}, skipping"
    warn "Create ${setup_script} in your app repo to automate app-specific setup"
    return
  fi

  step "Running app setup: ${setup_script}..."
  (cd "$APP_DIR" && bash "$full_path")
  info "App setup complete"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local shared_only=false
  local personal_only=false

  APP_REPO=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --shared-only)   shared_only=true; shift ;;
      --personal-only) personal_only=true; shift ;;
      -h|--help)       usage; exit 0 ;;
      -*)              error "Unknown option: $1"; usage; exit 1 ;;
      *)               APP_REPO="$1"; shift ;;
    esac
  done

  if [[ -z "$APP_REPO" ]]; then
    error "Missing required argument: <github-repo>"
    usage
    exit 1
  fi

  if [[ ! -f "$CONFIG_FILE" ]]; then
    warn "Config file not found at ${CONFIG_FILE}"
    warn "Copy config.example.toml to config.toml and customize it"
    exit 1
  fi

  export APP_DIR

  info "sprite-env setup starting..."
  info "Config: ${CONFIG_FILE}"
  info "App repo: ${APP_REPO}"
  info "App dir: ${APP_DIR}"
  echo

  # Clone the app repo first so .tool-versions is available for languages.sh
  clone_app_repo
  echo

  if [[ "$personal_only" != true ]]; then
    run_shared
    echo
  fi

  if [[ "$shared_only" != true ]]; then
    run_personal
    echo
  fi

  if [[ "$shared_only" != true && "$personal_only" != true ]]; then
    run_app_setup
    echo
  fi

  info "sprite-env setup complete!"
}

main "$@"
