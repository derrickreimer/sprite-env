# sprite-env

Modular, idempotent shell scripts that bootstrap a [Sprites.dev](https://sprites.dev) VM as a dev environment.

## Quick start

1. **Select your Sprite:**

   ```bash
   sprite use <sprite-name>
   ```

2. **Create your config files:**

   ```bash
   cp config.example.toml config.toml  # Required — set app_repo and other options
   cp .env.example .env                # Optional — set GITHUB_TOKEN, app secrets, etc.
   ```

3. **Run setup:**

   ```bash
   script/setup
   ```

   This single command handles everything: applies the network policy, installs and authenticates `gh` on the VM, clones repos, injects environment variables, and runs full setup.

### Non-interactive provisioning

Add `GITHUB_TOKEN` to your `.env` file to skip the interactive GitHub device flow.

### GitHub token scopes

The `gh` CLI requires these OAuth scopes:

- **`repo`** – full repository access
- **`read:org`** – read org and team membership (needed even for personal use, since `gh` uses it to resolve identities)
- **`workflow`** – update GitHub Actions workflow files (needed if you interact with workflows at all)
- **`read:packages`** / **`write:packages`** – if using GitHub Packages
- **`gist`** – if using `gh gist` commands

For a general-purpose dev VM bootstrap, the minimum viable set is:

```
repo,read:org,workflow
```

If you're generating the token manually (classic PAT), make sure to check all three. If you're using `gh auth login --with-token`, the token needs those scopes pre-granted before piping it in.

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
# Full setup (from host)
script/setup

# On the VM directly:
./setup.sh                  # Full setup
./setup.sh --shared-only    # Shared setup only (languages, services, tools)
./setup.sh --personal-only  # Personal setup only (dotfiles, editor, shell)
```

## App setup

The app repo is configured via `app_repo` in `config.toml` and cloned to `~/app`. After shared and personal setup, `setup.sh` looks for a `script/sprite-setup` script in the app repo and runs it. This keeps app-specific logic (installing deps, creating databases, copying secret configs) in the app repo where it belongs.

To customize the script path, set `app_setup_cmd` in `config.toml`.

## Environment variables

Create a `.env` file (from `.env.example`) with your environment variables. `script/setup` injects this file into the VM. On the VM, variables are:

- Exported in shell sessions via `~/.sprite-env-vars` (sourced from `~/.zshrc`)
- Copied to `~/app/.env` for the app

## Post-hibernation

When a Sprite wakes from hibernation, services need to be restarted. This happens automatically via systemd, or you can run manually:

```bash
sprite exec bash -c 'cd ~/sprite-env && ./wake.sh'
```

## Configuration

See `config.example.toml` for all available options.

## Project structure

```
script/setup          # Host-side orchestrator (run from host)
setup.sh              # VM-side orchestrator
wake.sh               # Post-hibernation recovery
config.example.toml   # Template configuration
.env.example          # Template environment variables
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
