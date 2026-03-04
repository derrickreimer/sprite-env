# sprite-env — Claude Code guidance

This repo contains setup scripts for bootstrapping a Sprites.dev VM as a SavvyCal Appointments dev environment.

## Project structure

```
setup.sh              # Main orchestrator — run this to bootstrap everything
wake.sh               # Post-hibernation service recovery
config.example.toml   # Template config — copy to config.toml
network-policy.sh     # Set Sprite network allowlist (run from host)
lib/helpers.sh        # Shared logging, TOML parsing, guard utilities
shared/               # Shared setup (languages, services, tools, MCP)
personal/             # Personal setup (dotfiles, editor, shell)
```

## Key conventions

- All scripts are **idempotent** — safe to re-run without side effects
- Scripts source `lib/helpers.sh` for shared utilities
- Configuration is in `config.toml` (flat TOML, parsed with grep/sed)
- Language versions come from the app repo's `.tool-versions` file
- **mise** is used as the version manager (not asdf)
- PostgreSQL 16 with user `postgres`/`postgres`

## The app being developed

The target application is **SavvyCal Appointments** — a Phoenix/Elixir app located at the path configured in `config.toml` (`app_dir`). Key details:

- Erlang/OTP 26, Elixir 1.17, Node.js 18
- PostgreSQL databases: `nova_dev`, `nova_test`
- Private hex repo: `ezsuite` (requires `EZSUITE_AUTH_KEY`)
- Uses mjml (Rust NIF) for email templates

## When editing these scripts

- Maintain idempotency — always check state before modifying
- Use the helper functions from `lib/helpers.sh` (info, warn, error, step, is_installed, toml_get)
- Keep scripts focused on a single concern
- Test changes can be verified by reading through the script logic — actual execution happens on a Sprite VM (Ubuntu), not macOS
