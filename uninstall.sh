#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$PROJECT_ROOT/bin/omarchy-bb-theme-sync" uninstall "$@"
