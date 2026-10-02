#!/bin/bash
#
# Run Glimpse's tests without losing your real settings.
#
# The unit tests are hosted inside the app and use UserDefaults.standard, so a run
# resets your work interval, break style, streak, and other settings. This script
# backs up Glimpse's preferences first and restores them afterwards, even if the
# tests fail or you press Ctrl-C.
#
# Usage: scripts/test.sh [extra xcodebuild args, e.g. -only-testing:GlimpseTests]

set -uo pipefail

DOMAIN="amanW.Glimpse"
BACKUP="$(mktemp -t glimpse-defaults).plist"

defaults export "$DOMAIN" "$BACKUP" 2>/dev/null || echo "No existing settings to back up."
restore() {
    if [ -s "$BACKUP" ]; then
        defaults delete "$DOMAIN" 2>/dev/null
        defaults import "$DOMAIN" "$BACKUP" && echo "Restored your Glimpse settings."
    fi
    rm -f "$BACKUP"
}
trap restore EXIT

cd "$(dirname "$0")/.."
xcodebuild test -scheme Glimpse -destination 'platform=macOS' "$@"
