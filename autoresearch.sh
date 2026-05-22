#!/usr/bin/env bash
set -euo pipefail

score=0
files_present=0
theme_refs_clean=0
entry_generic=0
hypr_score=0
executable_scripts=0
wallpaper_score=0
keybind_score=0
switcher_score=0
runtime_score=0
widget_runtime_score=0
compat_score=0
hypr_switch_score=0
wallpaper_switch_score=0
wallpaper_distinct_score=0
wallpaper_live_score=0
active_consistency_score=0
toggle_score=0
switcher_runtime_score=0
toggle_runtime_score=0
script_syntax_score=0
lotus_runtime_score=0
self_contained_score=0
nixos_app_score=0
nixos_brand_score=0
clipboard_layout_score=0
system_control_score=0
interface_font_score=0
notification_switch_score=0
hyprlock_switch_score=0
wofi_switch_score=0
terminal_switch_score=0
calendar_widget_score=0
media_widget_score=0
control_center_score=0
upstream_widget_keybind_score=0
polish_score=0
notification_center_score=0
live_status_score=0
media_artwork_score=0
wallpaper_visibility_score=0

expect_files=(
  ".config/quickshell/themes/yahr/ThemeShell.qml"
  ".config/quickshell/themes/yahr/Theme.qml"
  ".config/quickshell/themes/yahr/Bar.qml"
  ".config/quickshell/themes/yahr/WorkspaceBar.qml"
  ".config/quickshell/themes/yahr/PowerMenu.qml"
  ".config/quickshell/themes/yahr/QuickApps.qml"
  ".config/quickshell/themes/yahr/Clipboard.qml"
  ".config/quickshell/themes/yahr/AppLauncher.qml"
  ".config/quickshell/themes/yahr/Calendar.qml"
  ".config/quickshell/themes/yahr/Media.qml"
  ".config/quickshell/themes/yahr/ControlCenter.qml"
  ".config/quickshell/themes/yahr/Notifications.qml"
  ".config/quickshell/themes/yahr/apps.json"
  ".config/quickshell/themes/yahr/scripts/list-apps.sh"
)

for f in "${expect_files[@]}"; do
  [[ -f "$f" ]] && files_present=$((files_present + 1))
done
score=$((score + files_present * 10))

if [[ -f .config/quickshell/shell.qml ]] && rg -q 'ThemeShell\s*\{' .config/quickshell/shell.qml; then
  entry_generic=10
fi
score=$((score + entry_generic))

if [[ -d .config/quickshell/themes/yahr ]]; then
  dirty_refs=0
  if rg -n 'ThemeManager|themes/lotus|LotusShell|kitty|thunar|/home/bryan|sddm|papirus|vencord|\.find\(' .config/quickshell/themes/yahr >/tmp/yahr-refscan.txt 2>/dev/null; then
    dirty_refs=$(wc -l </tmp/yahr-refscan.txt)
  fi
  theme_refs_clean=$((30 - dirty_refs * 3))
  (( theme_refs_clean < 0 )) && theme_refs_clean=0
fi
score=$((score + theme_refs_clean))

if [[ -f .config/quickshell/themes/yahr/AppLauncher.qml ]] \
  && rg -q 'Quickshell\.shellDir \+ "/scripts/list-apps\.sh"' .config/quickshell/themes/yahr/AppLauncher.qml \
  && ! rg -q '\.config/quickshell/current/scripts/list-apps\.sh' .config/quickshell/themes/yahr/AppLauncher.qml; then
  self_contained_score=10
fi
score=$((score + self_contained_score))

if rg -q '/run/current-system/sw/share/applications' .config/quickshell/themes/yahr/scripts/list-apps.sh \
  && rg -q '/etc/profiles/per-user/\$USER/share/applications' .config/quickshell/themes/yahr/scripts/list-apps.sh; then
  app_count=$(.config/quickshell/themes/yahr/scripts/list-apps.sh | wc -l)
  if (( app_count > 0 )); then
    nixos_app_score=20
  fi
fi
score=$((score + nixos_app_score))

if rg -q 'glyph: ""' .config/quickshell/themes/yahr/Bar.qml \
  && ! rg -q 'glyph: "󰣇"' .config/quickshell/themes/yahr/Bar.qml; then
  nixos_brand_score=10
fi
score=$((score + nixos_brand_score))

if rg -q 'anchors.centerIn: parent' .config/quickshell/themes/yahr/Clipboard.qml \
  && rg -q 'theme.panelBg' .config/quickshell/themes/yahr/Clipboard.qml \
  && rg -q 'width: Math.min\(parent.width - 120, 860\)' .config/quickshell/themes/yahr/Clipboard.qml \
  && ! rg -q 'font.family: root.serif|text: "写"' .config/quickshell/themes/yahr/Clipboard.qml; then
  clipboard_layout_score=15
fi
score=$((score + clipboard_layout_score))

if rg -q 'nm-connection-editor' .config/quickshell/themes/yahr/Bar.qml \
  && rg -q 'blueman-manager' .config/quickshell/themes/yahr/Bar.qml \
  && rg -q 'pavucontrol' .config/quickshell/themes/yahr/Bar.qml \
  && rg -q 'wpctl get-volume @DEFAULT_AUDIO_SINK@' .config/quickshell/themes/yahr/Bar.qml \
  && rg -q 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle' .config/quickshell/themes/yahr/Bar.qml \
  && ! rg -q 'pactl|pamixer -t' .config/quickshell/themes/yahr/Bar.qml; then
  system_control_score=15
fi
score=$((score + system_control_score))

if rg -q 'fontSizeSmall: 20' .config/quickshell/themes/yahr/Theme.qml \
  && rg -q 'fontSizeNormal: 20' .config/quickshell/themes/yahr/Theme.qml \
  && rg -q 'fontSizeLarge: 20' .config/quickshell/themes/yahr/Theme.qml \
  && rg -q 'font\.pixelSize: theme\.fontSizeNormal' .config/quickshell/themes/yahr/AppLauncher.qml \
  && rg -q 'font\.pixelSize: theme\.fontSizeNormal' .config/quickshell/themes/yahr/Clipboard.qml \
  && rg -q 'font\.pixelSize: theme\.fontSizeNormal' .config/quickshell/themes/yahr/PowerMenu.qml \
  && [[ -f .config/mako/config ]] \
  && rg -q 'font=IoskeleyMono Nerd Font 20' .config/mako/config; then
  interface_font_score=20
fi
score=$((score + interface_font_score))

if [[ -f .config/mako/themes/lotus/config ]] \
  && [[ -f .config/mako/themes/yahr/config ]] \
  && rg -q '#212337ee|#a48cf2ff|#f265b5ff' .config/mako/themes/yahr/config \
  && rg -q 'font=IoskeleyMono Nerd Font 20' .config/mako/themes/yahr/config \
  && rg -q 'font=IoskeleyMono Nerd Font 20' .config/mako/themes/lotus/config \
  && rg -q 'copy_config "\$mako_target" "\$mako_dir/config"' .config/quickshell/switch-theme.sh \
  && rg -q 'makoctl reload' .config/quickshell/switch-theme.sh; then
  notification_switch_score=15
fi
score=$((score + notification_switch_score))

if [[ -f .config/wofi/themes/lotus/config ]] \
  && [[ -f .config/wofi/themes/lotus/style.css ]] \
  && [[ -f .config/wofi/themes/yahr/config ]] \
  && [[ -f .config/wofi/themes/yahr/style.css ]] \
  && cmp -s .config/wofi/themes/yahr/config .config/wofi/config \
  && cmp -s .config/wofi/themes/yahr/style.css .config/wofi/style.css \
  && rg -q 'allow_images=false' .config/wofi/themes/yahr/config \
  && rg -q 'transition: none' .config/wofi/themes/yahr/style.css \
  && rg -q '#212337|#a48cf2|#f265b5' .config/wofi/themes/yahr/style.css \
  && rg -q 'copy_config "\$wofi_config_target" "\$wofi_dir/config"' .config/quickshell/switch-theme.sh \
  && rg -q 'copy_config "\$wofi_style_target" "\$wofi_dir/style.css"' .config/quickshell/switch-theme.sh; then
  wofi_switch_score=15
fi
score=$((score + wofi_switch_score))

if [[ -f .config/ghostty/themes/lotus/config ]] \
  && [[ -f .config/ghostty/themes/yahr/config ]] \
  && cmp -s .config/ghostty/themes/yahr/config .config/ghostty/config \
  && rg -q 'foreground = #ebfafa' .config/ghostty/themes/yahr/config \
  && rg -q 'background = #212337' .config/ghostty/themes/yahr/config \
  && rg -q 'palette = 5=#f265b5' .config/ghostty/themes/yahr/config \
  && rg -q 'repo_ghostty_target=' .config/quickshell/switch-theme.sh \
  && rg -q 'Ghostty config is read-only; skipping terminal theme copy' .config/quickshell/switch-theme.sh \
  && rg -q 'copy_config "\$ghostty_target" "\$ghostty_dir/config"' .config/quickshell/switch-theme.sh; then
  terminal_switch_score=15
fi
score=$((score + terminal_switch_score))

if [[ -f .config/quickshell/themes/yahr/Calendar.qml ]] \
  && rg -q 'GridLayout' .config/quickshell/themes/yahr/Calendar.qml \
  && rg -q 'model: 42' .config/quickshell/themes/yahr/Calendar.qml \
  && rg -q 'shiftMonth' .config/quickshell/themes/yahr/Calendar.qml \
  && rg -q 'font\.pixelSize: 20' .config/quickshell/themes/yahr/Calendar.qml \
  && rg -q 'current/Calendar\.qml' .config/quickshell/themes/yahr/Bar.qml; then
  calendar_widget_score=15
fi
score=$((score + calendar_widget_score))

if [[ -f .config/quickshell/themes/yahr/Media.qml ]] \
  && rg -q 'playerctl metadata' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'playerctl " \+ action' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'progress' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'current/Media\.qml' .config/quickshell/themes/yahr/Bar.qml \
  && rg -q 'playerctl play-pause' .config/quickshell/themes/yahr/Bar.qml; then
  media_widget_score=15
fi
score=$((score + media_widget_score))

if [[ -f .config/quickshell/themes/yahr/Media.qml ]] \
  && rg -q 'mpris:artUrl' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'normalizedArtUrl' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'source: root.artUrl' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'Image.PreserveAspectCrop' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'visible: root.artUrl.length === 0' .config/quickshell/themes/yahr/Media.qml; then
  media_artwork_score=15
fi
score=$((score + media_artwork_score))

if [[ -f .config/quickshell/themes/yahr/ControlCenter.qml ]] \
  && rg -q 'nm-connection-editor' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'blueman-manager' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'pavucontrol' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'current/Media\.qml' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'current/Calendar\.qml' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'current/PowerMenu\.qml' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'current/ControlCenter\.qml' .config/quickshell/themes/yahr/Bar.qml; then
  control_center_score=15
fi
score=$((score + control_center_score))

if [[ -f .config/quickshell/themes/yahr/ControlCenter.qml ]] \
  && rg -q 'StatusCard' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q '/proc/stat' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q '/proc/meminfo' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'wpctl get-volume @DEFAULT_AUDIO_SINK@' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'nmcli -t -f DEVICE,STATE dev status' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'bluetoothctl show' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'playerctl metadata' .config/quickshell/themes/yahr/ControlCenter.qml; then
  live_status_score=15
fi
score=$((score + live_status_score))

if [[ -f .config/quickshell/themes/yahr/Notifications.qml ]] \
  && rg -q 'makoctl.*list.*-j' .config/quickshell/themes/yahr/Notifications.qml \
  && rg -q 'makoctl.*history.*-j' .config/quickshell/themes/yahr/Notifications.qml \
  && rg -q 'dismiss -n' .config/quickshell/themes/yahr/Notifications.qml \
  && rg -q 'restore' .config/quickshell/themes/yahr/Notifications.qml \
  && rg -q 'dismiss --all' .config/quickshell/themes/yahr/Notifications.qml \
  && rg -q 'current/Notifications\.qml' .config/quickshell/themes/yahr/Bar.qml \
  && rg -q 'current/Notifications\.qml' .config/quickshell/themes/yahr/ControlCenter.qml \
  && rg -q 'bind = \$mod SHIFT, N, exec, quickshell -p ~/.config/quickshell/current/Notifications\.qml' .config/hypr/binds.conf; then
  notification_center_score=15
fi
score=$((score + notification_center_score))

if [[ -f .config/hypr/theme.conf ]]; then
  rg -q 'a48cf2|212337|323449|f265b5' .config/hypr/theme.conf && hypr_score=$((hypr_score + 10))
  rg -q 'rounding = 1[0-9]|rounding = 12' .config/hypr/theme.conf && hypr_score=$((hypr_score + 5))
  rg -q 'shadow \{' .config/hypr/theme.conf && rg -q 'enabled = true' .config/hypr/theme.conf && hypr_score=$((hypr_score + 5))
fi
score=$((score + hypr_score))

if [[ -x .config/quickshell/themes/yahr/scripts/list-apps.sh ]]; then
  executable_scripts=10
fi
score=$((score + executable_scripts))

# Light syntax/static sanity checks for shell scripts and JSON.
script_syntax_ok=1
while IFS= read -r script; do
  bash -n "$script" || script_syntax_ok=0
done < <(find .config/quickshell -type f \( -name '*.sh' -o -path '*/scripts/*' \) | sort)
if [[ "$script_syntax_ok" == 1 ]]; then
  script_syntax_score=10
fi
score=$((score + script_syntax_score))
py=""
for candidate in /run/current-system/sw/bin/python3 /usr/bin/python3 /run/current-system/sw/bin/python /usr/bin/python python3 python; do
  if [[ -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
    py="$candidate"
    break
  fi
done

if [[ -n "$py" && -f .config/quickshell/themes/yahr/apps.json ]]; then
  "$py" -m json.tool .config/quickshell/themes/yahr/apps.json >/dev/null
fi

# Ensure QML braces are at least balanced enough to catch obvious truncation.
if [[ -n "$py" && -d .config/quickshell/themes/yahr ]]; then
  "$py" - <<'PY'
from pathlib import Path
for p in Path('.config/quickshell/themes/yahr').glob('*.qml'):
    text = p.read_text()
    if text.count('{') != text.count('}'):
        raise SystemExit(f'unbalanced braces: {p}')
PY
fi

if [[ -f .config/quickshell/themes/yahr/wallpapers/eldritch.jpg ]]; then
  wallpaper_score=$((wallpaper_score + 8))
fi
if [[ -f .config/hypr/hyprpaper.conf ]] && rg -q 'themes/yahr/wallpapers/eldritch\.jpg' .config/hypr/hyprpaper.conf; then
  wallpaper_score=$((wallpaper_score + 7))
fi
score=$((score + wallpaper_score))

if [[ -f .config/quickshell/themes/yahr/wallpapers/eldritch.jpg ]] \
  && [[ ! -L .config/hypr/hyprpaper.conf ]] \
  && ! rg -q 'eldritch\.png' .config/hypr .config/quickshell/themes/yahr 2>/dev/null; then
  wallpaper_size=$(wc -c < .config/quickshell/themes/yahr/wallpapers/eldritch.jpg)
  if (( wallpaper_size > 200000 )); then
    wallpaper_visibility_score=15
  fi
fi
score=$((score + wallpaper_visibility_score))

if [[ -f .config/hypr/binds.conf ]] && rg -q 'bind = \$mod, Space, exec, quickshell -p ~/.config/quickshell/current/AppLauncher\.qml' .config/hypr/binds.conf; then
  keybind_score=$((keybind_score + 10))
fi
if [[ -f .config/hypr/binds.conf ]] && rg -q 'bind = \$mod SHIFT, Space, exec, wofi --show drun' .config/hypr/binds.conf; then
  keybind_score=$((keybind_score + 5))
fi
score=$((score + keybind_score))

if [[ -f .config/hypr/binds.conf ]] \
  && rg -q 'bind = \$mod SHIFT, C, exec, quickshell -p ~/.config/quickshell/current/Calendar\.qml' .config/hypr/binds.conf \
  && rg -q 'bind = \$mod SHIFT, M, exec, quickshell -p ~/.config/quickshell/current/Media\.qml' .config/hypr/binds.conf \
  && rg -q 'bind = \$mod SHIFT, S, exec, quickshell -p ~/.config/quickshell/current/ControlCenter\.qml' .config/hypr/binds.conf; then
  upstream_widget_keybind_score=10
fi
score=$((score + upstream_widget_keybind_score))

if rg -q 'No applications found|No matches' .config/quickshell/themes/yahr/AppLauncher.qml \
  && rg -q 'type to search · enter to launch · esc to close' .config/quickshell/themes/yahr/AppLauncher.qml \
  && rg -q 'Clipboard history is empty|No clipboard matches' .config/quickshell/themes/yahr/Clipboard.qml \
  && rg -q 'copy something or adjust your filter' .config/quickshell/themes/yahr/Clipboard.qml \
  && rg -q 'No active player' .config/quickshell/themes/yahr/Media.qml \
  && rg -q 'space play/pause' .config/quickshell/themes/yahr/Media.qml; then
  polish_score=15
fi
score=$((score + polish_score))

if [[ -x .config/quickshell/switch-theme.sh ]] \
  && rg -q 'lotus\|yahr' .config/quickshell/switch-theme.sh \
  && rg -q 'ln -sfn "themes/\$theme"' .config/quickshell/switch-theme.sh \
  && ! rg -q 'sddm|papirus|vencord|kitty|thunar|/home/bryan' .config/quickshell/switch-theme.sh; then
  switcher_score=10
fi
score=$((score + switcher_score))

if command -v quickshell >/dev/null 2>&1; then
  test_dir=$(mktemp -d)
  trap 'rm -rf "$test_dir"' EXIT
  cat > "$test_dir/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "current"

ShellRoot {
  ThemeShell {}
}
QML
  for shell_theme in yahr lotus; do
    rm -f "$test_dir/current"
    ln -s "$PWD/.config/quickshell/themes/$shell_theme" "$test_dir/current"
    shell_log="$test_dir/${shell_theme}.log"
    shell_code=0
    timeout 2s quickshell -p "$test_dir" --no-duplicate --no-color >"$shell_log" 2>&1 || shell_code=$?
    if [[ "$shell_code" == 124 ]] && rg -q 'Configuration Loaded' "$shell_log" \
      && ! rg -q 'ERROR|TypeError|ReferenceError|Unable to assign' "$shell_log"; then
      if [[ "$shell_theme" == yahr ]]; then
        runtime_score=15
      else
        lotus_runtime_score=15
      fi
    fi
  done
fi
score=$((score + runtime_score + lotus_runtime_score))

if command -v quickshell >/dev/null 2>&1; then
  widget_ok=0
  for widget in PowerMenu AppLauncher Clipboard QuickApps Calendar Media ControlCenter Notifications; do
    widget_log=$(mktemp)
    widget_code=0
    timeout 2s quickshell -p "$PWD/.config/quickshell/themes/yahr/${widget}.qml" --no-duplicate --no-color >"$widget_log" 2>&1 || widget_code=$?
    if [[ "$widget_code" == 124 ]] && ! rg -q 'ERROR|TypeError|ReferenceError|Unable to assign' "$widget_log"; then
      widget_ok=$((widget_ok + 1))
    fi
    rm -f "$widget_log"
  done
  widget_runtime_score=$((widget_ok * 5))
fi
score=$((score + widget_runtime_score))

if [[ -f .config/quickshell/themes/lotus/ThemeShell.qml ]] \
  && [[ -f .config/quickshell/themes/lotus/AppLauncher.qml ]]; then
  compat_score=$((compat_score + 10))
fi
if command -v quickshell >/dev/null 2>&1 && [[ -f .config/quickshell/themes/lotus/AppLauncher.qml ]]; then
  compat_log=$(mktemp)
  compat_code=0
  timeout 2s quickshell -p "$PWD/.config/quickshell/themes/lotus/AppLauncher.qml" --no-duplicate --no-color >"$compat_log" 2>&1 || compat_code=$?
  if [[ "$compat_code" == 124 ]] && ! rg -q 'ERROR|TypeError|ReferenceError|Unable to assign' "$compat_log"; then
    compat_score=$((compat_score + 10))
  fi
  rm -f "$compat_log"
fi
score=$((score + compat_score))

if [[ -f .config/hypr/themes/lotus.conf ]] && [[ -f .config/hypr/themes/yahr.conf ]] \
  && rg -q 'copy_config "\$hypr_target" "\$hypr_dir/theme.conf"' .config/quickshell/switch-theme.sh \
  && rg -q 'hyprctl reload' .config/quickshell/switch-theme.sh; then
  hypr_switch_score=15
fi
score=$((score + hypr_switch_score))

if [[ -f .config/hypr/themes/lotus/hyprlock.conf ]] \
  && [[ -f .config/hypr/themes/yahr/hyprlock.conf ]] \
  && cmp -s .config/hypr/themes/yahr/hyprlock.conf .config/hypr/hyprlock.conf \
  && rg -q 'themes/yahr/wallpapers/eldritch\.jpg' .config/hypr/themes/yahr/hyprlock.conf \
  && rg -q 'font_size = 86' .config/hypr/themes/yahr/hyprlock.conf \
  && rg -q 'rgba\(164, 140, 242' .config/hypr/themes/yahr/hyprlock.conf \
  && rg -q 'copy_config "\$hyprlock_target" "\$hypr_dir/hyprlock.conf"' .config/quickshell/switch-theme.sh; then
  hyprlock_switch_score=15
fi
score=$((score + hyprlock_switch_score))

if [[ -f .config/hypr/hyprpaper/lotus.conf ]] && [[ -f .config/hypr/hyprpaper/yahr.conf ]] \
  && rg -q 'themes/lotus/wallpapers/lotus\.(png|jpg)' .config/hypr/hyprpaper/lotus.conf \
  && rg -q 'copy_config "\$hyprpaper_target" "\$hypr_dir/hyprpaper.conf"' .config/quickshell/switch-theme.sh; then
  wallpaper_switch_score=15
fi
score=$((score + wallpaper_switch_score))

lotus_wallpaper=""
if [[ -f .config/quickshell/themes/lotus/wallpapers/lotus.jpg ]]; then
  lotus_wallpaper=.config/quickshell/themes/lotus/wallpapers/lotus.jpg
elif [[ -f .config/quickshell/themes/lotus/wallpapers/lotus.png ]]; then
  lotus_wallpaper=.config/quickshell/themes/lotus/wallpapers/lotus.png
fi
if [[ -n "$lotus_wallpaper" ]] && [[ -f .config/quickshell/themes/yahr/wallpapers/eldritch.jpg ]]; then
  lotus_hash=$(sha256sum "$lotus_wallpaper" | awk '{print $1}')
  yahr_hash=$(sha256sum .config/quickshell/themes/yahr/wallpapers/eldritch.jpg | awk '{print $1}')
  if [[ "$lotus_hash" != "$yahr_hash" ]]; then
    wallpaper_distinct_score=10
  fi
fi
score=$((score + wallpaper_distinct_score))

if rg -q 'hyprpaper reload ,' .config/quickshell/switch-theme.sh \
  && rg -q 'pkill hyprpaper' .config/quickshell/switch-theme.sh \
  && rg -q 'wallpaper_path=\$\{wallpaper_path/#\\~\/\$HOME\}' .config/quickshell/switch-theme.sh; then
  wallpaper_live_score=10
fi
score=$((score + wallpaper_live_score))

active_theme=""
if [[ -L .config/quickshell/current ]]; then
  current_target=$(readlink .config/quickshell/current)
  case "$current_target" in
    themes/lotus) active_theme=lotus ;;
    themes/yahr) active_theme=yahr ;;
  esac
fi
if [[ -n "$active_theme" ]] \
  && cmp -s ".config/hypr/themes/${active_theme}.conf" .config/hypr/theme.conf \
  && cmp -s ".config/hypr/hyprpaper/${active_theme}.conf" .config/hypr/hyprpaper.conf \
  && cmp -s ".config/hypr/themes/${active_theme}/hyprlock.conf" .config/hypr/hyprlock.conf; then
  active_consistency_score=15
fi
score=$((score + active_consistency_score))

if [[ -x .config/quickshell/toggle-theme.sh ]] \
  && rg -q 'themes/yahr\).*next=lotus' .config/quickshell/toggle-theme.sh \
  && rg -q 'themes/lotus\).*next=yahr' .config/quickshell/toggle-theme.sh \
  && rg -q 'switch-theme\.sh" "\$next"' .config/quickshell/toggle-theme.sh \
  && rg -q 'bind = \$mod SHIFT, R, exec, ~/.config/quickshell/toggle-theme\.sh' .config/hypr/binds.conf; then
  toggle_score=10
fi
score=$((score + toggle_score))

switch_test_dir=$(mktemp -d)
mkdir -p "$switch_test_dir/.config" "$switch_test_dir/bin"
cp -a .config/quickshell "$switch_test_dir/.config/"
cp -a .config/hypr "$switch_test_dir/.config/"
cp -a .config/mako "$switch_test_dir/.config/"
cp -a .config/wofi "$switch_test_dir/.config/"
cp -a .config/ghostty "$switch_test_dir/.config/"
for cmd in hyprctl hyprpaper quickshell pkill makoctl; do
  cat > "$switch_test_dir/bin/$cmd" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$switch_test_dir/bin/$cmd"
done
switch_ok=1
for theme in lotus yahr; do
  if ! HOME="$switch_test_dir" XDG_CONFIG_HOME="$switch_test_dir/.config" PATH="$switch_test_dir/bin:$PATH" "$switch_test_dir/.config/quickshell/switch-theme.sh" "$theme" >/dev/null 2>&1; then
    switch_ok=0
    break
  fi
  [[ "$(readlink "$switch_test_dir/.config/quickshell/current")" == "themes/$theme" ]] || switch_ok=0
  cmp -s "$switch_test_dir/.config/hypr/themes/$theme.conf" "$switch_test_dir/.config/hypr/theme.conf" || switch_ok=0
  cmp -s "$switch_test_dir/.config/hypr/hyprpaper/$theme.conf" "$switch_test_dir/.config/hypr/hyprpaper.conf" || switch_ok=0
  cmp -s "$switch_test_dir/.config/hypr/themes/$theme/hyprlock.conf" "$switch_test_dir/.config/hypr/hyprlock.conf" || switch_ok=0
  cmp -s "$switch_test_dir/.config/mako/themes/$theme/config" "$switch_test_dir/.config/mako/config" || switch_ok=0
  cmp -s "$switch_test_dir/.config/wofi/themes/$theme/config" "$switch_test_dir/.config/wofi/config" || switch_ok=0
  cmp -s "$switch_test_dir/.config/wofi/themes/$theme/style.css" "$switch_test_dir/.config/wofi/style.css" || switch_ok=0
  cmp -s "$switch_test_dir/.config/ghostty/themes/$theme/config" "$switch_test_dir/.config/ghostty/config" || switch_ok=0
done
if [[ "$switch_ok" == 1 ]]; then
  switcher_runtime_score=15
fi

toggle_ok=1
HOME="$switch_test_dir" XDG_CONFIG_HOME="$switch_test_dir/.config" PATH="$switch_test_dir/bin:$PATH" "$switch_test_dir/.config/quickshell/switch-theme.sh" yahr >/dev/null 2>&1 || toggle_ok=0
HOME="$switch_test_dir" XDG_CONFIG_HOME="$switch_test_dir/.config" PATH="$switch_test_dir/bin:$PATH" "$switch_test_dir/.config/quickshell/toggle-theme.sh" >/dev/null 2>&1 || toggle_ok=0
[[ "$(readlink "$switch_test_dir/.config/quickshell/current")" == "themes/lotus" ]] || toggle_ok=0
cmp -s "$switch_test_dir/.config/hypr/themes/lotus.conf" "$switch_test_dir/.config/hypr/theme.conf" || toggle_ok=0
cmp -s "$switch_test_dir/.config/hypr/hyprpaper/lotus.conf" "$switch_test_dir/.config/hypr/hyprpaper.conf" || toggle_ok=0
cmp -s "$switch_test_dir/.config/hypr/themes/lotus/hyprlock.conf" "$switch_test_dir/.config/hypr/hyprlock.conf" || toggle_ok=0
cmp -s "$switch_test_dir/.config/mako/themes/lotus/config" "$switch_test_dir/.config/mako/config" || toggle_ok=0
cmp -s "$switch_test_dir/.config/wofi/themes/lotus/config" "$switch_test_dir/.config/wofi/config" || toggle_ok=0
cmp -s "$switch_test_dir/.config/wofi/themes/lotus/style.css" "$switch_test_dir/.config/wofi/style.css" || toggle_ok=0
cmp -s "$switch_test_dir/.config/ghostty/themes/lotus/config" "$switch_test_dir/.config/ghostty/config" || toggle_ok=0
HOME="$switch_test_dir" XDG_CONFIG_HOME="$switch_test_dir/.config" PATH="$switch_test_dir/bin:$PATH" "$switch_test_dir/.config/quickshell/toggle-theme.sh" >/dev/null 2>&1 || toggle_ok=0
[[ "$(readlink "$switch_test_dir/.config/quickshell/current")" == "themes/yahr" ]] || toggle_ok=0
cmp -s "$switch_test_dir/.config/hypr/themes/yahr.conf" "$switch_test_dir/.config/hypr/theme.conf" || toggle_ok=0
cmp -s "$switch_test_dir/.config/hypr/hyprpaper/yahr.conf" "$switch_test_dir/.config/hypr/hyprpaper.conf" || toggle_ok=0
cmp -s "$switch_test_dir/.config/hypr/themes/yahr/hyprlock.conf" "$switch_test_dir/.config/hypr/hyprlock.conf" || toggle_ok=0
cmp -s "$switch_test_dir/.config/mako/themes/yahr/config" "$switch_test_dir/.config/mako/config" || toggle_ok=0
cmp -s "$switch_test_dir/.config/wofi/themes/yahr/config" "$switch_test_dir/.config/wofi/config" || toggle_ok=0
cmp -s "$switch_test_dir/.config/wofi/themes/yahr/style.css" "$switch_test_dir/.config/wofi/style.css" || toggle_ok=0
cmp -s "$switch_test_dir/.config/ghostty/themes/yahr/config" "$switch_test_dir/.config/ghostty/config" || toggle_ok=0
if [[ "$toggle_ok" == 1 ]]; then
  toggle_runtime_score=15
fi
rm -rf "$switch_test_dir"
score=$((score + switcher_runtime_score + toggle_runtime_score))

printf 'METRIC port_score=%s\n' "$score"
printf 'METRIC files_present=%s\n' "$files_present"
printf 'METRIC theme_refs_clean=%s\n' "$theme_refs_clean"
printf 'METRIC entry_generic=%s\n' "$entry_generic"
printf 'METRIC hypr_score=%s\n' "$hypr_score"
printf 'METRIC executable_scripts=%s\n' "$executable_scripts"
printf 'METRIC wallpaper_score=%s\n' "$wallpaper_score"
printf 'METRIC keybind_score=%s\n' "$keybind_score"
printf 'METRIC switcher_score=%s\n' "$switcher_score"
printf 'METRIC runtime_score=%s\n' "$runtime_score"
printf 'METRIC widget_runtime_score=%s\n' "$widget_runtime_score"
printf 'METRIC compat_score=%s\n' "$compat_score"
printf 'METRIC hypr_switch_score=%s\n' "$hypr_switch_score"
printf 'METRIC wallpaper_switch_score=%s\n' "$wallpaper_switch_score"
printf 'METRIC wallpaper_distinct_score=%s\n' "$wallpaper_distinct_score"
printf 'METRIC wallpaper_live_score=%s\n' "$wallpaper_live_score"
printf 'METRIC active_consistency_score=%s\n' "$active_consistency_score"
printf 'METRIC toggle_score=%s\n' "$toggle_score"
printf 'METRIC switcher_runtime_score=%s\n' "$switcher_runtime_score"
printf 'METRIC toggle_runtime_score=%s\n' "$toggle_runtime_score"
printf 'METRIC script_syntax_score=%s\n' "$script_syntax_score"
printf 'METRIC lotus_runtime_score=%s\n' "$lotus_runtime_score"
printf 'METRIC self_contained_score=%s\n' "$self_contained_score"
printf 'METRIC nixos_app_score=%s\n' "$nixos_app_score"
printf 'METRIC nixos_brand_score=%s\n' "$nixos_brand_score"
printf 'METRIC clipboard_layout_score=%s\n' "$clipboard_layout_score"
printf 'METRIC system_control_score=%s\n' "$system_control_score"
printf 'METRIC interface_font_score=%s\n' "$interface_font_score"
printf 'METRIC notification_switch_score=%s\n' "$notification_switch_score"
printf 'METRIC hyprlock_switch_score=%s\n' "$hyprlock_switch_score"
printf 'METRIC wofi_switch_score=%s\n' "$wofi_switch_score"
printf 'METRIC terminal_switch_score=%s\n' "$terminal_switch_score"
printf 'METRIC calendar_widget_score=%s\n' "$calendar_widget_score"
printf 'METRIC media_widget_score=%s\n' "$media_widget_score"
printf 'METRIC control_center_score=%s\n' "$control_center_score"
printf 'METRIC upstream_widget_keybind_score=%s\n' "$upstream_widget_keybind_score"
printf 'METRIC polish_score=%s\n' "$polish_score"
printf 'METRIC notification_center_score=%s\n' "$notification_center_score"
printf 'METRIC live_status_score=%s\n' "$live_status_score"
printf 'METRIC media_artwork_score=%s\n' "$media_artwork_score"
printf 'METRIC wallpaper_visibility_score=%s\n' "$wallpaper_visibility_score"
