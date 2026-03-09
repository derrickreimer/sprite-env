#!/usr/bin/env bash
# Install language runtimes via mise, reading versions from .tool-versions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/helpers.sh"

# ---------------------------------------------------------------------------
# mise (version manager)
# ---------------------------------------------------------------------------

install_mise() {
  if is_installed mise; then
    info "mise already installed"
    return
  fi

  step "Installing mise..."
  curl -fsSL https://mise.run | sh

  # Ensure mise is on PATH for this session
  export PATH="$HOME/.local/bin:$PATH"

  # Activate mise in shell profiles
  local shell_rc
  for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_rc" ]] && ! grep -q 'mise activate' "$shell_rc"; then
      echo 'eval "$(mise activate)"' >> "$shell_rc"
    fi
  done

  info "mise installed"
}

# ---------------------------------------------------------------------------
# Language runtimes
# ---------------------------------------------------------------------------

install_runtime() {
  local name="$1" version="$2"

  if [[ -z "$version" ]]; then
    warn "No version found for ${name}, skipping"
    return
  fi

  local current
  current="$(mise current "$name" 2>/dev/null || true)"

  if [[ "$current" == *"$version"* ]]; then
    info "${name} ${version} already installed"
    return
  fi

  step "Installing ${name} ${version}..."
  mise install "${name}@${version}" --yes
  mise use --global "${name}@${version}"
  info "${name} ${version} installed"
}

read_tool_version() {
  local tool="$1"
  local tool_versions_file="${APP_DIR}/.tool-versions"

  if [[ ! -f "$tool_versions_file" ]]; then
    error ".tool-versions not found at ${tool_versions_file}"
    return 1
  fi

  grep "^${tool} " "$tool_versions_file" | awk '{print $2}'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

disable_sprite_languages() {
  local env_file="/etc/profile.d/languages_env"

  if [[ ! -f "$env_file" ]]; then
    return
  fi

  step "Disabling Sprite built-in language management..."
  sudo bash -c "cat > $env_file" <<'EOF'
# Disabled by sprite-env — using mise for language management instead.
# Original values overrode MIX_HOME, HEX_HOME, and others.
EOF

  # Move Sprite language wrappers out of the way
  if [[ -d "/.sprite/bin" ]]; then
    for cmd in elixir elixirc iex mix elixir-version; do
      if [[ -f "/.sprite/bin/$cmd" ]]; then
        sudo mv "/.sprite/bin/$cmd" "/.sprite/bin/${cmd}.disabled"
      fi
    done
  fi

  # Remove /.sprite/languages from PATH for this session
  export PATH="${PATH/\/.sprite\/languages\/elixir\/current\/bin:/}"

  # Unset for the current session
  unset MIX_HOME HEX_HOME NVM_DIR SDKMAN_DIR RBENV_ROOT
  unset -f elixir elixirc iex mix 2>/dev/null || true
  info "Sprite language management disabled"
}

main() {
  disable_sprite_languages
  install_mise

  # Ensure mise is available
  export PATH="$HOME/.local/bin:$PATH"
  eval "$(mise activate bash 2>/dev/null || true)"

  local erlang_version elixir_version nodejs_version

  erlang_version="$(read_tool_version erlang)"
  elixir_version="$(read_tool_version elixir)"
  nodejs_version="$(read_tool_version nodejs)"

  install_runtime erlang "$erlang_version"
  install_runtime elixir "$elixir_version"
  install_runtime nodejs "$nodejs_version"

  step "Generating mise shims..."
  mise reshim
  info "All language runtimes installed"
}

main "$@"
