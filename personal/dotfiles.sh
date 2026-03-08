#!/usr/bin/env bash
# Clone and bootstrap personal dotfiles
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/helpers.sh"

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local repo bootstrap_cmd target_dir

  repo="$(toml_get "$CONFIG_FILE" "dotfiles_repo")"
  bootstrap_cmd="$(toml_get "$CONFIG_FILE" "dotfiles_bootstrap_cmd")"

  if [[ -z "$repo" ]]; then
    info "No dotfiles_repo configured, skipping"
    return
  fi

  target_dir="$HOME/.dotfiles"
  bootstrap_cmd="${bootstrap_cmd:-./install.sh}"

  if [[ -d "$target_dir" ]]; then
    info "Dotfiles already cloned at ${target_dir}, pulling latest..."
    git -C "$target_dir" pull --ff-only || warn "Could not pull dotfiles"
  else
    step "Cloning dotfiles from ${repo}..."
    gh repo clone "$repo" "$target_dir"
  fi

  if [[ -n "$bootstrap_cmd" ]]; then
    step "Running dotfiles bootstrap: ${bootstrap_cmd}..."
    (cd "$target_dir" && bash -c "$bootstrap_cmd")
  fi

  info "Dotfiles setup complete"
}

main "$@"
