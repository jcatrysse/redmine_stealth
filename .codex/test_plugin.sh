#!/usr/bin/env bash
#
# Runs the plugin's tests in the Redmine checkout prepared by
# ./.codex/redmine_clone.sh and ./.codex/test_setup.sh (same RMP_DB).
# The plugin copy under redmine/plugins/ is refreshed first, so the run
# always sees the working tree.
#
#   ./.codex/test_plugin.sh                       # all tests in test/
#   ./.codex/test_plugin.sh test/unit/foo_test.rb # one file
#
# Minitest (Redmine's own framework, `rake redmine:plugins:test`); a spec/
# directory, if one is ever added, runs with rspec.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REDMINE_DIR="${REDMINE_DIR:-$ROOT/redmine}"
case "$REDMINE_DIR" in /*) ;; *) REDMINE_DIR="$ROOT/$REDMINE_DIR" ;; esac
PLUGIN_NAME="$(basename "$ROOT")"
export RAILS_ENV=test

rsync -a --delete --exclude "/$(basename "$REDMINE_DIR")/" --exclude /.git/ "$ROOT/" "$REDMINE_DIR/plugins/$PLUGIN_NAME/"

cd "$REDMINE_DIR"
mkdir -p tmp/test-results

if [ -d "plugins/$PLUGIN_NAME/spec" ]; then
  bundle exec rspec "plugins/$PLUGIN_NAME/spec" --format progress
fi

if [ $# -gt 0 ]; then
  files=()
  for f in "$@"; do files+=("plugins/$PLUGIN_NAME/$f"); done
  bundle exec ruby -Itest -e 'ARGV.each { |f| require File.expand_path(f) }' "${files[@]}"
else
  bundle exec rake redmine:plugins:test NAME="$PLUGIN_NAME"
fi
