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

Bootstrap a Sprites.dev VM as a SavvyCal Appointments dev environment.

Options:
  --shared-only     Run only shared setup (languages, services, tools)
  --personal-only   Run only personal setup (dotfiles, editor, shell)
  -h, --help        Show this help message

Environment variables:
  SPRITE_ENV_CONFIG  Path to config.toml (default: ./config.toml)
  APP_DIR            Path to the app repo (overrides config.toml)
  EZSUITE_AUTH_KEY   Auth key for the ezsuite private hex repo
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

  cd "$APP_DIR"

  # Configure private hex repo
  if [[ -n "${EZSUITE_AUTH_KEY:-}" ]]; then
    step "Configuring ezsuite hex repo..."
    mix hex.repo add ezsuite https://hex.pm/repos/ezsuite --auth-key "$EZSUITE_AUTH_KEY" 2>/dev/null || \
      info "ezsuite hex repo already configured"
  else
    warn "EZSUITE_AUTH_KEY not set — skipping private hex repo config"
  fi

  # Copy dev.secret.exs if it doesn't exist
  if [[ ! -f config/dev.secret.exs ]] && [[ -f config/dev.secret.exs.example ]]; then
    step "Copying dev.secret.exs from example..."
    cp config/dev.secret.exs.example config/dev.secret.exs
    info "dev.secret.exs created"
  fi

  # Install dependencies
  step "Installing Elixir dependencies..."
  mix local.hex --force --if-missing
  mix local.rebar --force --if-missing
  mix deps.get

  step "Installing Node.js dependencies..."
  npm install --prefix assets

  # Setup database
  step "Setting up databases..."
  mix ecto.setup

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
