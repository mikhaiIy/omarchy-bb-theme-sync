#!/usr/bin/env bash
set -euo pipefail

PROGRAM=omarchy-bb-theme-sync
PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
COMMAND_TARGET=$PROJECT_ROOT/bin/$PROGRAM
HOOK_TARGET=$PROJECT_ROOT/hooks/theme-set.d/$PROGRAM
COMMAND_LINK=${HOME:?}/.local/bin/$PROGRAM
HOOK_LINK=${HOME:?}/.config/omarchy/hooks/theme-set.d/$PROGRAM

die() { printf '%s: %s\n' "$PROGRAM install" "$*" >&2; exit 1; }

install_link() {
  local target=$1 link=$2 label=$3 current
  mkdir -p "$(dirname -- "$link")"
  if [ -L "$link" ]; then
    current=$(readlink "$link")
    [ "$current" = "$target" ] || die "$label already points elsewhere: $link -> $current (remove it first)"
  elif [ -e "$link" ]; then
    die "$label path already exists and is not a symlink: $link"
  else
    ln -s "$target" "$link"
  fi
  printf '%s: %s -> %s\n' "$label" "$link" "$target"
}

case ${1:-} in
  '') ;;
  --help|-h)
    printf 'Usage: ./install.sh\n\nInstalls symlinks into ~/.local/bin and ~/.config/omarchy/hooks/theme-set.d.\n'
    exit 0
    ;;
  *) die "unknown option: $1" ;;
esac

[ -x "$COMMAND_TARGET" ] || die "command is not executable: $COMMAND_TARGET"
[ -x "$HOOK_TARGET" ] || die "hook is not executable: $HOOK_TARGET"
install_link "$COMMAND_TARGET" "$COMMAND_LINK" 'Command'
install_link "$HOOK_TARGET" "$HOOK_LINK" 'Theme hook'
printf '%s\n' 'Installed. Run omarchy-bb-theme-sync [theme-slug] for a manual sync.'
