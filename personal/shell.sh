#!/usr/bin/env bash
# Shell customization: tmux, starship, dev-start script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/helpers.sh"

# ---------------------------------------------------------------------------
# tmux
# ---------------------------------------------------------------------------

install_tmux() {
  if ! toml_get_bool "$CONFIG_FILE" "tmux"; then
    info "tmux not enabled in config, skipping"
    return
  fi

  if is_installed tmux; then
    info "tmux already installed"
  else
    step "Installing tmux..."
    sudo apt-get install -y -qq tmux
    info "tmux installed"
  fi

  create_dev_start_script
}

# ---------------------------------------------------------------------------
# starship prompt
# ---------------------------------------------------------------------------

install_starship() {
  if ! toml_get_bool "$CONFIG_FILE" "starship"; then
    info "starship not enabled in config, skipping"
    return
  fi

  if is_installed starship; then
    info "starship already installed"
    return
  fi

  step "Installing starship..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
  info "starship installed"

  # Add to shell profiles
  local shell_rc
  for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_rc" ]] && ! grep -q 'starship init' "$shell_rc"; then
      echo 'eval "$(starship init bash)"' >> "$shell_rc"
    fi
  done
}

# ---------------------------------------------------------------------------
# dev-start script (tmux layout)
# ---------------------------------------------------------------------------

create_dev_start_script() {
  local dev_start="$HOME/.local/bin/dev-start"

  ensure_dir "$HOME/.local/bin"

  if [[ -f "$dev_start" ]]; then
    info "dev-start script already exists"
    return
  fi

  step "Creating dev-start script..."
  cat > "$dev_start" << 'DEVSTART'
#!/usr/bin/env bash
# Launch a tmux dev session for the appointments app
set -euo pipefail

SESSION="dev"
APP_DIR="${APP_DIR:-$HOME/app}"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already exists, attaching..."
  tmux attach -t "$SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" -c "$APP_DIR"

# Main pane: editor / general work
tmux rename-window -t "$SESSION:0" "editor"

# Second window: Phoenix server
tmux new-window -t "$SESSION" -n "server" -c "$APP_DIR"
tmux send-keys -t "$SESSION:server" "mix phx.server" Enter

# Third window: general shell
tmux new-window -t "$SESSION" -n "shell" -c "$APP_DIR"

# Select editor window
tmux select-window -t "$SESSION:editor"
tmux attach -t "$SESSION"
DEVSTART

  chmod +x "$dev_start"
  info "dev-start script created at ${dev_start}"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  install_tmux
  install_starship

  info "Shell setup complete"
}

main "$@"
