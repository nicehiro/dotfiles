#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <lotus|yahr>\n' "$(basename "$0")" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

theme="$1"
case "$theme" in
  lotus|yahr) ;;
  *) usage; exit 2 ;;
esac

copy_config() {
  local source="$1"
  local destination="$2"
  local tmp
  tmp=$(mktemp "${destination}.XXXXXX")
  cp "$source" "$tmp"
  mv "$tmp" "$destination"
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_config_home=$(cd -- "$script_dir/.." && pwd)

xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
quickshell_dir="$xdg_config_home/quickshell"
hypr_dir="$xdg_config_home/hypr"
mako_dir="$xdg_config_home/mako"
wofi_dir="$xdg_config_home/wofi"
ghostty_dir="$xdg_config_home/ghostty"
qs_target="$quickshell_dir/themes/$theme"
hypr_target="$hypr_dir/themes/$theme.conf"
hyprpaper_target="$hypr_dir/hyprpaper/$theme.conf"
hyprlock_target="$hypr_dir/themes/$theme/hyprlock.conf"
mako_target="$mako_dir/themes/$theme/config"
wofi_config_target="$wofi_dir/themes/$theme/config"
wofi_style_target="$wofi_dir/themes/$theme/style.css"
ghostty_target="$ghostty_dir/themes/$theme/config"
repo_ghostty_target="$repo_config_home/ghostty/themes/$theme/config"
current="$quickshell_dir/current"

if [[ ! -d "$qs_target" ]]; then
  printf 'Quickshell theme not found: %s\n' "$qs_target" >&2
  exit 1
fi
if [[ ! -f "$hypr_target" ]]; then
  printf 'Hyprland theme not found: %s\n' "$hypr_target" >&2
  exit 1
fi
if [[ ! -f "$hyprpaper_target" ]]; then
  printf 'Hyprpaper theme not found: %s\n' "$hyprpaper_target" >&2
  exit 1
fi
if [[ ! -f "$hyprlock_target" ]]; then
  printf 'Hyprlock theme not found: %s\n' "$hyprlock_target" >&2
  exit 1
fi
if [[ ! -f "$mako_target" ]]; then
  printf 'Mako theme not found: %s\n' "$mako_target" >&2
  exit 1
fi
if [[ ! -f "$wofi_config_target" ]]; then
  printf 'Wofi config theme not found: %s\n' "$wofi_config_target" >&2
  exit 1
fi
if [[ ! -f "$wofi_style_target" ]]; then
  printf 'Wofi style theme not found: %s\n' "$wofi_style_target" >&2
  exit 1
fi
if [[ ! -f "$ghostty_target" && -f "$repo_ghostty_target" ]]; then
  ghostty_target="$repo_ghostty_target"
fi

ln -sfn "themes/$theme" "$current"
copy_config "$hypr_target" "$hypr_dir/theme.conf"
copy_config "$hyprpaper_target" "$hypr_dir/hyprpaper.conf"
copy_config "$hyprlock_target" "$hypr_dir/hyprlock.conf"
copy_config "$mako_target" "$mako_dir/config"
copy_config "$wofi_config_target" "$wofi_dir/config"
copy_config "$wofi_style_target" "$wofi_dir/style.css"
if [[ -f "$ghostty_target" && -w "$ghostty_dir/config" ]]; then
  copy_config "$ghostty_target" "$ghostty_dir/config"
elif [[ -f "$ghostty_target" ]]; then
  printf 'Ghostty config is read-only; skipping terminal theme copy: %s\n' "$ghostty_dir/config" >&2
else
  printf 'Ghostty theme not found; skipping terminal theme copy: %s\n' "$ghostty_dir/themes/$theme/config" >&2
fi
wallpaper_path=$(awk -F= '/^wallpaper[[:space:]]*=/{print $2; exit}' "$hyprpaper_target" | sed 's/^[[:space:]]*,[[:space:]]*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
wallpaper_path=${wallpaper_path/#\~/$HOME}

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

if [[ -n "$wallpaper_path" ]] && command -v hyprpaper >/dev/null 2>&1; then
  hyprpaper reload ,"$wallpaper_path" >/dev/null 2>&1 || {
    pkill hyprpaper >/dev/null 2>&1 || true
    hyprpaper >/dev/null 2>&1 &
  }
fi

if command -v makoctl >/dev/null 2>&1; then
  makoctl reload >/dev/null 2>&1 || true
fi

if command -v quickshell >/dev/null 2>&1; then
  quickshell kill >/dev/null 2>&1 || true
  quickshell --no-duplicate >/dev/null 2>&1 &
fi

printf 'Switched theme to %s\n' "$theme"
