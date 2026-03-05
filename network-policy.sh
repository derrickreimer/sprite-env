#!/usr/bin/env bash
# Set the Sprites.dev network policy for the SavvyCal dev environment.
# Run this from the HOST machine (not inside the Sprite VM).
#
# Usage: ./network-policy.sh <sprite-name>
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <sprite-name>"
  echo ""
  echo "Sets the network allowlist for the given Sprite so that"
  echo "the SavvyCal appointments dev environment can reach all"
  echo "required external services."
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
  "releases.hashicorp.com"

  # Erlang/Elixir builds
  "binaries2.erlang-solutions.com"
  "builds.hex.pm"
  "repo.hex.pm"

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

echo "Setting network policy for Sprite: ${SPRITE_NAME}"
echo "Allowing ${#ALLOWED_DOMAINS[@]} domains..."

# Join domains with commas for the sprite CLI
DOMAIN_LIST=$(IFS=,; echo "${ALLOWED_DOMAINS[*]}")

sprite network-policy set "$SPRITE_NAME" --allow "$DOMAIN_LIST"

echo "Network policy set successfully."
echo ""
echo "Allowed domains:"
for domain in "${ALLOWED_DOMAINS[@]}"; do
  echo "  - ${domain}"
done
