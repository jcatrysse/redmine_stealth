#!/usr/bin/env bash
#
# Prepares the Redmine checkout from ./.codex/redmine_clone.sh for the plugin's
# tests: system packages, a database server, config/database.yml (test), gems,
# the test database and the plugin migrations.
#
#   ./.codex/test_setup.sh                  # PostgreSQL (default)
#   RMP_DB=mariadb ./.codex/test_setup.sh   # MariaDB (mysql2 adapter)
#
# Ruby: the ruby on PATH is used when it satisfies the `ruby` line of Redmine's
# Gemfile; otherwise mise installs a matching one (MISE_BIN).
# Switching RMP_DB rewrites config/database.yml (test section) and re-creates
# the test database; run start_server.sh --reset afterwards for the e2e one.
set -euo pipefail

REDMINE_DIR="$(cd "${REDMINE_DIR:-redmine}" && pwd)"
RAILS_ENV=test
MISE_BIN="${MISE_BIN:-mise}"
RMP_DB="${RMP_DB:-postgresql}"
export RAILS_ENV

ruby_ok() {
  command -v ruby >/dev/null 2>&1 || return 1
  ruby -e '
    line = File.readlines(ARGV[0]).grep(/^\s*ruby\s/).first or exit 0
    reqs = line.scan(/["\x27]([^"\x27]+)["\x27]/).flatten
    exit Gem::Requirement.new(*reqs).satisfied_by?(Gem::Version.new(RUBY_VERSION)) ? 0 : 1
  ' "$REDMINE_DIR/Gemfile"
}

detect_ruby_version() {
  # Highest x.y below the Gemfile's upper bound, or its ~> / exact version.
  local line
  line="$(grep -E "^[[:space:]]*ruby " "$REDMINE_DIR/Gemfile" | head -n 1 || true)"
  ruby_from_line="$(echo "$line" | sed -E -n "s/.*['\"]([0-9]+\.[0-9]+(\.[0-9]+)?)['\"].*/\1/p")"
  echo "${ruby_from_line:-3.3}"
}

SUDO=""; [ "$(id -u)" = 0 ] || SUDO="sudo"
as_postgres() { if [ "$(id -u)" = 0 ]; then runuser -u postgres -- "$@"; else sudo -u postgres "$@"; fi; }

case "$RMP_DB" in
  postgresql|postgres|pg)
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq build-essential libpq-dev postgresql postgresql-contrib
    $SUDO service postgresql start
    if as_postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='redmine'" | grep -q 1; then
      as_postgres psql -qc "ALTER ROLE redmine WITH LOGIN CREATEDB PASSWORD 'redmine';"
    else
      as_postgres psql -qc "CREATE ROLE redmine WITH LOGIN CREATEDB PASSWORD 'redmine';"
    fi
    db_yaml='test:
  adapter: postgresql
  database: redmine_test
  host: localhost
  username: redmine
  password: redmine
  encoding: unicode'
    ;;
  mariadb|mysql)
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq build-essential libmariadb-dev mariadb-server
    $SUDO service mariadb start
    $SUDO mysql -e "CREATE USER IF NOT EXISTS 'redmine'@'localhost' IDENTIFIED BY 'redmine';
      CREATE USER IF NOT EXISTS 'redmine'@'%' IDENTIFIED BY 'redmine';
      GRANT ALL ON \`redmine_test\`.* TO 'redmine'@'localhost';
      GRANT ALL ON \`redmine_test\`.* TO 'redmine'@'%';
      GRANT ALL ON \`redmine_e2e\`.* TO 'redmine'@'localhost';
      GRANT ALL ON \`redmine_e2e\`.* TO 'redmine'@'%';
      FLUSH PRIVILEGES;"
    db_yaml='test:
  adapter: mysql2
  database: redmine_test
  host: 127.0.0.1
  port: 3306
  username: redmine
  password: redmine
  encoding: utf8mb4
  variables:
    tx_isolation: "READ-COMMITTED"'
    ;;
  *) echo "ERROR: RMP_DB must be postgresql or mariadb, not '$RMP_DB'" >&2; exit 2 ;;
esac

echo "$db_yaml" > "$REDMINE_DIR/config/database.yml"
# A schema.rb dumped by the other adapter would be loaded instead of migrating.
rm -f "$REDMINE_DIR/db/schema.rb"

cd "$REDMINE_DIR"

if ! grep -q "rails-controller-testing" Gemfile.local 2>/dev/null; then
  cat <<'EOF' >> Gemfile.local
group :test do
  gem 'rails-controller-testing'
end
EOF
fi

bundle_cmd=(bundle)
if ! ruby_ok; then
  RUBY_VERSION_WANTED="$(detect_ruby_version)"
  command -v "$MISE_BIN" >/dev/null 2>&1 || {
    echo "Ruby on PATH does not satisfy Redmine's Gemfile and mise is missing; install a matching Ruby." >&2; exit 1; }
  "$MISE_BIN" install "ruby@$RUBY_VERSION_WANTED"
  bundle_cmd=("$MISE_BIN" exec "ruby@$RUBY_VERSION_WANTED" -- bundle)
fi

bundle config set --local without 'development'
bundle config set --local path 'vendor/bundle'
"${bundle_cmd[@]}" install --quiet
"${bundle_cmd[@]}" exec rake db:drop db:create db:migrate
"${bundle_cmd[@]}" exec rake redmine:plugins:migrate
rm -f db/schema.rb
echo "Test database ready on $RMP_DB."
