#!/bin/sh

set -eu

REPOSITORY_PATH="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"
SECRETS_FILE="$REPOSITORY_PATH/Config/Secrets.xcconfig"

: > "$SECRETS_FILE"

if [ -n "${REVENUECAT_API_KEY:-}" ]; then
    printf 'REVENUECAT_API_KEY = %s\n' "$REVENUECAT_API_KEY" >> "$SECRETS_FILE"
fi
