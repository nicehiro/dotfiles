#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
current="$config_dir/current"
current_target=""

if [[ -L "$current" ]]; then
  current_target=$(readlink "$current")
fi

case "$current_target" in
  themes/yahr) next=lotus ;;
  themes/lotus) next=yahr ;;
  *) next=yahr ;;
esac

exec "$config_dir/switch-theme.sh" "$next"
