#!/usr/bin/env bash
# Post-hibernation recovery — restart services and optionally launch dev layout
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/helpers.sh"

# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------

start_postgres() {
  if pg_isready -q 2>/dev/null; then
    info "PostgreSQL is already running"
    return
  fi

  step "Starting PostgreSQL..."
  sudo systemctl start postgresql || sudo pg_ctlcluster 16 main start
  info "PostgreSQL started"
}

# ---------------------------------------------------------------------------
# Dev layout
# ---------------------------------------------------------------------------

launch_dev_session() {
  if ! toml_get_bool "$CONFIG_FILE" "tmux" 2>/dev/null; then
    return
  fi

  if ! is_installed tmux; then
    return
  fi

  if tmux has-session -t dev 2>/dev/null; then
    info "tmux dev session already running"
    return
  fi

  if is_installed dev-start; then
    step "Launching dev tmux session..."
    dev-start
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  info "sprite-env wake recovery..."

  start_postgres
  launch_dev_session

  info "Wake recovery complete"
}

main "$@"
