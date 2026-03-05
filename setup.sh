#!/usr/bin/env bash
# Main orchestrator — runs shared and personal setup scripts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/helpers.sh"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap a Sprites.dev VM as a dev environment.

Options:
  --shared-only     Run only shared setup (languages, services, tools)
  --personal-only   Run only personal setup (dotfiles, editor, shell)
  -h, --help        Show this help message

Environment variables:
  SPRITE_ENV_CONFIG  Path to config.toml (default: ./config.toml)
  APP_DIR            Path to the app repo (overrides config.toml)
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

run_app_setup() {
  step "=== App setup ==="

  if [[ ! -d "$APP_DIR" ]]; then
    warn "App directory not found at ${APP_DIR}, skipping app setup"
    return
  fi

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

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --shared-only)   shared_only=true; shift ;;
      --personal-only) personal_only=true; shift ;;
      -h|--help)       usage; exit 0 ;;
      *)               error "Unknown option: $1"; usage; exit 1 ;;
    esac
  done

  if [[ ! -f "$CONFIG_FILE" ]]; then
    warn "Config file not found at ${CONFIG_FILE}"
    warn "Copy config.example.toml to config.toml and customize it"
    exit 1
  fi

  info "sprite-env setup starting..."
  info "Config: ${CONFIG_FILE}"
  info "App dir: ${APP_DIR}"
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
