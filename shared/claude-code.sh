#!/usr/bin/env bash
# Configure Claude Code MCP servers
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/helpers.sh"

# ---------------------------------------------------------------------------
# MCP servers
# ---------------------------------------------------------------------------

add_mcp_server() {
  local name="$1" url="$2"

  # Check if already configured
  if claude mcp list 2>/dev/null | grep -q "$name"; then
    info "MCP server '${name}' already configured"
    return
  fi

  step "Adding MCP server: ${name}..."
  claude mcp add --transport sse "$name" "$url"
  info "MCP server '${name}' added"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  if ! is_installed claude; then
    warn "Claude Code CLI not found, skipping MCP configuration"
    return
  fi

  add_mcp_server "github"  "https://api.githubcopilot.com/mcp/"
  add_mcp_server "linear"  "https://mcp.linear.app/sse"

  info "Claude Code MCP servers configured"
}

main "$@"
