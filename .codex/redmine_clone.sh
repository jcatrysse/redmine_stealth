#!/usr/bin/env bash
set -euo pipefail

# Usage: ./.codex/redmine_clone.sh [branch]
#   branch: 7.0-stable-GEOxyz (default), 7.0-stable, 6.1-stable, 5.1-stable, ...
#   REDMINE_REPO_URL: default the GEOxyz fork, which carries the upstream
#   *-stable branches as well as the *-GEOxyz ones.
REDMINE_VERSION="${1:-7.0-stable-GEOxyz}"
REDMINE_DIR="${REDMINE_DIR:-redmine}"
REDMINE_REPO_URL="${REDMINE_REPO_URL:-https://github.com/jcatrysse/redmine.git}"

if ! git ls-remote --heads "$REDMINE_REPO_URL" "$REDMINE_VERSION" | grep -q "$REDMINE_VERSION"; then
  echo "ERROR: Redmine branch '$REDMINE_VERSION' not found on $REDMINE_REPO_URL" >&2
  exit 1
fi

if [ ! -d "$REDMINE_DIR/.git" ]; then
  git clone --depth 1 --branch "$REDMINE_VERSION" "$REDMINE_REPO_URL" "$REDMINE_DIR"
else
  (
    cd "$REDMINE_DIR"
    git fetch --depth 1 origin "$REDMINE_VERSION:refs/remotes/origin/$REDMINE_VERSION"
    git checkout -B "$REDMINE_VERSION" "origin/$REDMINE_VERSION"
  )
fi

PLUGIN_NAME="$(basename "$(pwd)")"
mkdir -p "$REDMINE_DIR/plugins/$PLUGIN_NAME"
# Anchored: an unanchored "redmine/" would also drop lib/redmine/ from the copy.
rsync -a --delete --exclude /redmine/ --exclude "/$(basename "$REDMINE_DIR")/" --exclude /.git/ ./ "$REDMINE_DIR/plugins/$PLUGIN_NAME/"
