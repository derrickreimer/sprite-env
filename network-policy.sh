#!/usr/bin/env bash
# Set the Sprites.dev network policy for a dev environment.
# Run this from the HOST machine using the sprite CLI.
#
# Usage: ./network-policy.sh <sprite-name>
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <sprite-name>"
  echo ""
  echo "Sets the network allowlist for the given Sprite so that"
  echo "the dev environment can reach all required external services."
  exit 1
fi

if ! command -v sprite &>/dev/null; then
  echo "Error: sprite CLI not found."
  echo "Install it from https://docs.sprites.dev/cli/installation/"
  exit 1
fi

SPRITE_NAME="$1"

# Domains required for development
ALLOWED_DOMAINS=(
  # Package registries
  "hex.pm"
  "repo.hex.pm"
  "builds.hex.pm"
  "registry.npmjs.org"
  "crates.io"
  "static.crates.io"
  "index.crates.io"

  # Language installers & runtimes
  "mise.run"
  "mise.jdx.dev"
  "github.com"
  "api.github.com"
  "objects.githubusercontent.com"
  "raw.githubusercontent.com"
  "release-assets.githubusercontent.com"
  "releases.hashicorp.com"

  # Erlang/Elixir builds
  "erlang.org"
  "www.erlang.org"
  "binaries2.erlang-solutions.com"

  # Node.js
  "nodejs.org"

  # Rust
  "sh.rustup.rs"
  "static.rust-lang.org"

  # GitHub CLI
  "cli.github.com"

  # Starship prompt
  "starship.rs"

  # System packages
  "archive.ubuntu.com"
  "security.ubuntu.com"
  "apt.postgresql.org"
  "apt-archive.postgresql.org"
  "www.postgresql.org"
  "ppa.launchpadcontent.net"

  # GitHub Copilot MCP
  "api.githubcopilot.com"

  # Linear MCP
  "mcp.linear.app"
  "api.linear.app"

  # General dev services
  "api.anthropic.com"
  "statsigapi.net"
  "sentry.io"
)

# Build JSON rules array
RULES="["
for i in "${!ALLOWED_DOMAINS[@]}"; do
  [[ $i -gt 0 ]] && RULES+=","
  RULES+="{\"action\":\"allow\",\"domain\":\"${ALLOWED_DOMAINS[$i]}\"}"
done
RULES+="]"

echo "Setting network policy for Sprite: ${SPRITE_NAME}"
echo "Allowing ${#ALLOWED_DOMAINS[@]} domains..."

sprite api -s "$SPRITE_NAME" /policy/network -d "{\"rules\":${RULES}}"

echo ""
echo "Network policy set successfully."
echo ""
echo "Allowed domains:"
for domain in "${ALLOWED_DOMAINS[@]}"; do
  echo "  - ${domain}"
done
