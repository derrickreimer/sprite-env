# sprite-env

Modular, idempotent shell scripts that bootstrap a [Sprites.dev](https://sprites.dev) VM as a dev environment.

## Quick start

1. **Set the network policy** (from your host machine):

   ```bash
   ./network-policy.sh <sprite-name>
   ```

2. **Log into the VM and run the bootstrap script.** This installs `gh`, authenticates with GitHub, clones repos, and creates `config.toml`:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/derrickreimer/sprite-env/main/bootstrap.sh | bash
   ```

3. **Edit config and run setup:**

   ```bash
   cd ~/Code/derrickreimer/sprite-env
   # Edit config.toml with your preferences
   ./setup.sh
   ```

## What gets installed

### Shared (every developer)

| Category   | Details                                                                           |
| ---------- | --------------------------------------------------------------------------------- |
| Tools      | build-essential, curl, git, jq, ripgrep, fd, gh, imagemagick, inotify-tools, Rust |
| Languages  | Erlang, Elixir, Node.js (versions from `.tool-versions`)                          |
| Services   | PostgreSQL 16 (user: `postgres`/`postgres`)                                       |
| Claude MCP | GitHub and Linear MCP servers                                                     |

### Personal (per config.toml)

| Category | Details                                        |
| -------- | ---------------------------------------------- |
| Dotfiles | Clone and bootstrap from your dotfiles repo    |
| Editor   | Neovim install + headless plugin sync          |
| Shell    | tmux, starship prompt, `dev-start` tmux layout |

## Usage

```bash
# Full setup
./setup.sh

# Shared setup only (no personal customization)
./setup.sh --shared-only

# Personal setup only (dotfiles, editor, shell)
./setup.sh --personal-only
```

## App setup

After shared and personal setup, `setup.sh` looks for a `script/sprite-setup` script in your app repo and runs it. This keeps app-specific logic (installing deps, creating databases, copying secret configs) in the app repo where it belongs.

To customize the script path, set `app_setup_cmd` in `config.toml`.

## Post-hibernation

When a Sprite wakes from hibernation, services need to be restarted. This happens automatically via systemd, or you can run manually:

```bash
./wake.sh
```

## Configuration

See `config.example.toml` for all available options.

## Project structure

```
setup.sh              # Main orchestrator
wake.sh               # Post-hibernation recovery
config.example.toml   # Template configuration
network-policy.sh     # Sprite network allowlist (run from host)
lib/helpers.sh        # Shared utilities
shared/
  languages.sh        # Erlang, Elixir, Node.js via mise
  services.sh         # PostgreSQL 16
  tools.sh            # System packages, gh, Rust
  claude-code.sh      # MCP server configuration
personal/
  dotfiles.sh         # Clone and bootstrap dotfiles
  editor.sh           # Editor installation
  shell.sh            # tmux, starship, dev-start script
```
