#!/usr/bin/env bash
# Bootstrap a fresh Sprite VM.
#
# Paste this onto a new VM to get past the initial auth barrier:
#   curl -fsSL <raw-url> | bash
#
# Or just run it directly after copying onto the VM.
set -euo pipefail

# ---------------------------------------------------------------------------
# Config — edit these to match your setup
# ---------------------------------------------------------------------------

SPRITE_ENV_REPO="derrickreimer/sprite-env"
SPRITE_ENV_DIR="$HOME/sprite-env"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

info()  { echo -e "\033[0;32m[info]\033[0m  $*"; }
step()  { echo -e "\033[0;36m[step]\033[0m  $*"; }
error() { echo -e "\033[0;31m[error]\033[0m $*" >&2; }

# ---------------------------------------------------------------------------
# Install gh CLI
# ---------------------------------------------------------------------------

install_gh() {
  if command -v gh &>/dev/null; then
    info "GitHub CLI already installed"
    return
  fi

  step "Installing GitHub CLI..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq curl

  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq gh

  info "GitHub CLI installed"
}

# ---------------------------------------------------------------------------
# Authenticate
# ---------------------------------------------------------------------------

auth_gh() {
  if gh auth status &>/dev/null; then
    info "Already authenticated with GitHub"
    return
  fi

  step "Authenticating with GitHub..."
  gh auth login
}

# ---------------------------------------------------------------------------
# Clone repos
# ---------------------------------------------------------------------------

clone_repo() {
  local repo="$1" target="$2"

  if [[ -d "$target" ]]; then
    info "${repo} already cloned at ${target}"
    return
  fi

  step "Cloning ${repo}..."
  mkdir -p "$(dirname "$target")"
  gh repo clone "$repo" "$target"
  info "${repo} cloned"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  echo ""
  echo "=== sprite-env bootstrap ==="
  echo ""

  install_gh
  auth_gh

  clone_repo "$SPRITE_ENV_REPO" "$SPRITE_ENV_DIR"

  if [[ ! -f "${SPRITE_ENV_DIR}/config.toml" ]]; then
    step "Creating config.toml from example..."
    cp "${SPRITE_ENV_DIR}/config.example.toml" "${SPRITE_ENV_DIR}/config.toml"
    info "config.toml created — edit ${SPRITE_ENV_DIR}/config.toml to customize"
  fi

  echo ""
  info "Bootstrap complete! Next steps:"
  echo ""
  echo "  cd ${SPRITE_ENV_DIR}"
  echo "  # Edit config.toml with your preferences"
  echo "  ./setup.sh"
  echo ""
}

main "$@"
