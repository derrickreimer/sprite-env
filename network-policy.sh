#!/usr/bin/env bash
# Set the Sprites.dev network policy for a dev environment.
# Run this from the HOST machine (not inside the Sprite VM).
#
# Usage: ./network-policy.sh <sprite-name>
#
# Requires SPRITES_TOKEN env var (create at sprites.dev/account).
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <sprite-name>"
  echo ""
  echo "Sets the network allowlist for the given Sprite so that"
  echo "the dev environment can reach all required external services."
  echo ""
  echo "Requires SPRITES_TOKEN env var."
  exit 1
fi

if [[ -z "${SPRITES_TOKEN:-}" ]]; then
  echo "Error: SPRITES_TOKEN is not set."
  echo "Create a token at https://sprites.dev/account"
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

# Build JSON rules array
RULES="["
for i in "${!ALLOWED_DOMAINS[@]}"; do
  [[ $i -gt 0 ]] && RULES+=","
  RULES+="{\"action\":\"allow\",\"domain\":\"${ALLOWED_DOMAINS[$i]}\"}"
done
RULES+="]"

echo "Setting network policy for Sprite: ${SPRITE_NAME}"
echo "Allowing ${#ALLOWED_DOMAINS[@]} domains..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  "https://api.sprites.dev/v1/sprites/${SPRITE_NAME}/policy/network" \
  -H "Authorization: Bearer ${SPRITES_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"rules\":${RULES}}")

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  echo "Network policy set successfully."
else
  echo "Error: API returned HTTP ${HTTP_CODE}"
  exit 1
fi

echo ""
echo "Allowed domains:"
for domain in "${ALLOWED_DOMAINS[@]}"; do
  echo "  - ${domain}"
done
