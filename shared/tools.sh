#!/usr/bin/env bash
# Install CLI tools and system dependencies
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/helpers.sh"

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------

APT_PACKAGES=(
  build-essential
  curl
  git
  jq
  ripgrep
  fd-find
  imagemagick
  inotify-tools
  locales
  unzip
  wget
  autoconf
  libncurses-dev
  libssl-dev
  libwxgtk3.2-dev   # Erlang wx support
  libxml2-utils
  xsltproc
  fop
)

install_apt_packages() {
  step "Installing system packages..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq "${APT_PACKAGES[@]}"
  info "System packages installed"
}

# ---------------------------------------------------------------------------
# Locale
# ---------------------------------------------------------------------------

configure_locale() {
  if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
    info "en_US.UTF-8 locale already available"
    return
  fi

  step "Generating en_US.UTF-8 locale..."
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
  info "Locale configured"
}

# ---------------------------------------------------------------------------
# GitHub CLI
# ---------------------------------------------------------------------------

install_gh() {
  if is_installed gh; then
    info "GitHub CLI already installed"
    return
  fi

  step "Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq gh
  info "GitHub CLI installed"
}

# ---------------------------------------------------------------------------
# Rust (for mjml NIF compilation)
# ---------------------------------------------------------------------------

install_rust() {
  if is_installed rustc; then
    info "Rust already installed"
    return
  fi

  step "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
  source "$HOME/.cargo/env"
  info "Rust installed"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  install_apt_packages
  configure_locale
  install_gh
  install_rust

  info "All tools installed"
}

main "$@"
