#!/usr/bin/env bash
# Install and configure PostgreSQL
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/helpers.sh"

PG_VERSION="16"

# ---------------------------------------------------------------------------
# Install PostgreSQL
# ---------------------------------------------------------------------------

install_postgres() {
  if is_installed psql && psql --version | grep -q "${PG_VERSION}"; then
    info "PostgreSQL ${PG_VERSION} already installed"
    return
  fi

  step "Installing PostgreSQL ${PG_VERSION}..."

  # Add the PostgreSQL apt repo if not already configured
  if [[ ! -f /etc/apt/sources.list.d/pgdg.list ]]; then
    sudo apt-get install -y -qq curl ca-certificates
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | sudo gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
      | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null
  fi

  sudo apt-get update -qq
  sudo apt-get install -y -qq postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} libpq-dev
  info "PostgreSQL ${PG_VERSION} installed"
}

# ---------------------------------------------------------------------------
# Start & configure
# ---------------------------------------------------------------------------

start_postgres() {
  if pg_isready -q 2>/dev/null; then
    info "PostgreSQL is already running"
    return
  fi

  step "Starting PostgreSQL..."
  sudo pg_ctlcluster ${PG_VERSION} main start || sudo systemctl start postgresql
  info "PostgreSQL started"
}

configure_postgres_user() {
  local role_exists
  role_exists="$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='postgres'" 2>/dev/null || true)"

  # Ensure the postgres role has the expected password and superuser privileges
  step "Configuring postgres superuser role..."
  sudo -u postgres psql -c "ALTER ROLE postgres WITH SUPERUSER LOGIN PASSWORD 'postgres';" 2>/dev/null
  info "postgres role configured"
}

configure_pg_hba() {
  local hba_file="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

  if [[ ! -f "$hba_file" ]]; then
    warn "pg_hba.conf not found at ${hba_file}, skipping auth config"
    return
  fi

  # Allow local connections with md5 (password) auth for all users
  if grep -q "local.*all.*all.*trust" "$hba_file"; then
    info "pg_hba.conf already allows local trust connections"
    return
  fi

  step "Configuring pg_hba.conf for local trust auth..."
  sudo sed -i 's/local\s\+all\s\+all\s\+peer/local   all             all                                     trust/' "$hba_file"
  sudo systemctl reload postgresql || sudo pg_ctlcluster ${PG_VERSION} main reload
  info "pg_hba.conf configured"
}

enable_autostart() {
  if systemctl is-enabled postgresql &>/dev/null; then
    info "PostgreSQL auto-start already enabled"
    return
  fi

  step "Enabling PostgreSQL auto-start..."
  sudo systemctl enable postgresql
  info "PostgreSQL auto-start enabled"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  install_postgres
  start_postgres
  configure_pg_hba
  configure_postgres_user
  enable_autostart

  info "PostgreSQL ${PG_VERSION} setup complete"
}

main "$@"
