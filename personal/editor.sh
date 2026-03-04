#!/usr/bin/env bash
# Install and configure the preferred editor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/helpers.sh"

# ---------------------------------------------------------------------------
# Neovim
# ---------------------------------------------------------------------------

install_neovim() {
  if is_installed nvim; then
    info "Neovim already installed"
    return
  fi

  step "Installing Neovim..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq neovim
  info "Neovim installed"
}

sync_neovim_plugins() {
  step "Syncing Neovim plugins (headless)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || \
    nvim --headless +PlugInstall +qall 2>/dev/null || \
    info "No recognized plugin manager found, skipping plugin sync"
  info "Neovim plugins synced"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local editor
  editor="$(toml_get "$CONFIG_FILE" "editor")"

  case "${editor,,}" in
    neovim|nvim)
      install_neovim
      sync_neovim_plugins
      ;;
    ""|none)
      info "No editor configured, skipping"
      ;;
    *)
      info "Editor '${editor}' — no automated setup available"
      ;;
  esac
}

main "$@"
