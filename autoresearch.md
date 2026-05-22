# Autoresearch: Yahr Quickshell Theme Port

## Objective
Port the visual style of `bgibson72/yahr-quickshell` into this dotfiles repo as a new, reversible Quickshell theme while preserving the existing Hyprland workflow and app choices. The target theme should live under `.config/quickshell/themes/yahr/` and be switchable through `.config/quickshell/current`.

## Metrics
- **Primary**: `port_score` (unitless, higher is better) — structural completeness and static quality of the yahr port.
- **Secondary**:
  - `files_present` — expected yahr theme files exist.
  - `theme_refs_clean` — avoids upstream singleton `ThemeManager` and hardcoded lotus paths in yahr files.
  - `entry_generic` — `shell.qml` uses generic `ThemeShell`.
  - `hypr_score` — Hyprland yahr/eldritch visual integration exists.
  - `executable_scripts` — theme scripts are executable where applicable.
  - `wallpaper_score` — curated yahr wallpaper asset and hyprpaper integration exist.
  - `keybind_score` — Hyprland binds expose implemented yahr widgets via theme-local `current` paths while preserving a fallback launcher.
  - `switcher_score` — a lightweight local theme switcher exists without upstream full-rice side effects.
  - `runtime_score` — an isolated Quickshell launch of the yahr theme loads cleanly without QML/runtime errors.
  - `widget_runtime_score` — standalone yahr widgets launched by keybinds load cleanly without QML/runtime errors.
  - `compat_score` — lotus remains compatible with generic `ThemeShell` and `current/AppLauncher.qml` keybinds.
  - `hypr_switch_score` — the lightweight switcher also restores the matching Hyprland visual theme.
  - `wallpaper_switch_score` — the lightweight switcher also restores the matching hyprpaper wallpaper config.
  - `wallpaper_distinct_score` — lotus and yahr use distinct curated wallpaper assets.
  - `wallpaper_live_score` — the switcher applies the selected wallpaper to a running hyprpaper session.
  - `active_consistency_score` — committed active Quickshell, Hyprland theme, and hyprpaper configs all point to the same theme.
  - `toggle_score` — a one-key theme toggle is available and delegates to the safe switcher.
  - `switcher_runtime_score` — `switch-theme.sh` works for both themes in an isolated fake HOME without mutating the live session.
  - `toggle_runtime_score` — `toggle-theme.sh` alternates yahr↔lotus correctly in an isolated fake HOME.
  - `script_syntax_score` — all maintained Quickshell shell scripts pass `bash -n` syntax checks.
  - `lotus_runtime_score` — the generic `ThemeShell` entry also loads the lotus shell cleanly for rollback.
  - `self_contained_score` — yahr standalone widgets avoid depending on mutable `current` paths for their own helper scripts.
  - `nixos_app_score` — the yahr launcher discovers NixOS desktop-entry locations and returns apps.
  - `nixos_brand_score` — the yahr bar uses NixOS branding instead of the upstream Arch icon.
  - `clipboard_layout_score` — yahr clipboard uses a centered yahr-style glass panel instead of lotus-derived/right-biased visuals.
  - `system_control_score` — yahr status modules use installed NixOS helpers for network, Bluetooth, and PipeWire audio.
  - `interface_font_score` — yahr app launcher, clipboard, power menu, and mako notifications use a consistent 20px readable font baseline.
  - `notification_switch_score` — lotus/yahr mako notification theme snapshots exist and the local switcher applies/reloads the matching notification theme.
  - `hyprlock_switch_score` — lotus/yahr hyprlock theme snapshots exist and the local switcher applies the matching lockscreen theme.
  - `wofi_switch_score` — lightweight lotus/yahr wofi fallback themes exist and the local switcher applies the matching config/style.
  - `terminal_switch_score` — Ghostty lotus/yahr palette snapshots exist and the local switcher applies the matching terminal theme.
  - `calendar_widget_score` — a yahr-styled calendar popup exists, is reachable from the bar clock, and validates as a standalone widget.
  - `media_widget_score` — a yahr-styled playerctl media popup exists, is reachable from the bar, and validates as a standalone widget.
  - `control_center_score` — a yahr-styled control center exists, exposes status/helper shortcuts, and validates as a standalone widget.
  - `upstream_widget_keybind_score` — calendar, media, and control center widgets have direct Hyprland keybinds through theme-local current paths.
  - `polish_score` — yahr launcher, clipboard, and media surfaces provide clear empty states and keyboard/help hints.
  - `notification_center_score` — a yahr-styled mako notification/history center exists, is reachable from bar/control center/keybind, and validates as a standalone widget.
  - `live_status_score` — the yahr control center includes live CPU, memory, battery, network, Bluetooth, audio, and media status.
  - `media_artwork_score` — the yahr media widget reads MPRIS art URLs and displays album artwork with a themed fallback.
  - `wallpaper_visibility_score` — yahr uses a non-black curated wallpaper asset and active hyprpaper config points directly at it without stale lotus symlinks.

## How to Run
`./autoresearch.sh` — outputs `METRIC name=number` lines. It performs shell/JSON/QML static checks, short isolated Quickshell smoke tests for both themes, and isolated fake-HOME switcher/toggle tests.

## Files in Scope
- `.config/quickshell/shell.qml` — Quickshell entrypoint; should instantiate `ThemeShell` from the active `current` symlink.
- `.config/quickshell/themes/lotus/` — may receive compatibility entries such as `ThemeShell.qml` and `AppLauncher.qml` so the existing lotus theme keeps working with generic keybinds.
- `.config/quickshell/themes/yahr/` — new yahr/Eldritch-inspired theme implementation.
- `.config/hypr/theme.conf` — active Hyprland visual theme.
- `.config/hypr/themes/lotus.conf`, `.config/hypr/themes/yahr.conf` — switchable Hyprland visual theme snapshots.
- `.config/hypr/binds.conf` — may be updated only for theme-local app launcher if the yahr launcher is implemented.
- `.config/hypr/hyprpaper.conf` — active hyprpaper wallpaper config.
- `.config/hypr/hyprlock.conf`, `.config/hypr/themes/lotus/hyprlock.conf`, `.config/hypr/themes/yahr/hyprlock.conf` — active and switchable lockscreen theme configs.
- `.config/hypr/hyprpaper/lotus.conf`, `.config/hypr/hyprpaper/yahr.conf` — switchable wallpaper config snapshots.
- `.config/quickshell/themes/lotus/wallpapers/`, `.config/quickshell/themes/yahr/wallpapers/` — curated wallpaper assets for each theme.
- `.config/quickshell/switch-theme.sh` — lightweight symlink-based theme switcher for lotus/yahr only.
- `.config/quickshell/toggle-theme.sh` — toggles between lotus and yahr by delegating to `switch-theme.sh`.
- `.config/mako/config`, `.config/mako/themes/lotus/config`, `.config/mako/themes/yahr/config` — active and switchable notification theme configs.
- `.config/wofi/config`, `.config/wofi/style.css`, `.config/wofi/themes/lotus/`, `.config/wofi/themes/yahr/` — active and switchable fallback launcher themes.
- `.config/ghostty/config`, `.config/ghostty/themes/lotus/config`, `.config/ghostty/themes/yahr/config` — active and switchable terminal theme configs.
- `autoresearch.md`, `autoresearch.sh`, `autoresearch.ideas.md` — experiment memory and scoring.

## Off Limits
- Do not run or port upstream `install.sh`.
- Do not copy upstream configs wholesale over `.config/hypr/hyprland.conf`.
- Do not add SDDM, Papirus, Firefox, Vencord, VS Code, Neovim, Starship, Kitty, or GTK sync automation in the first pass.
- Do not change unrelated `.pi/agent/settings.json` or other unrelated dotfiles.
- Do not introduce new package dependencies.

## Constraints
- Preserve current apps: `ghostty`, `nautilus`, `wofi`, `hyprpaper`, `mako`, `hypridle`, `hyprlock`, `cliphist`, `playerctl`.
- Use installed helpers for status modules: `nm-connection-editor`, `blueman-manager`, `pavucontrol`, and `wpctl`; do not require `pactl`.
- Keep yahr Quickshell widget interface text, mako notifications, and wofi fallback text at a readable 20px baseline unless a purely decorative glyph intentionally differs.
- Keep wofi fallback lightweight: avoid images and CSS transitions/animations because the current theme feels slow.
- NixOS app discovery must include `/run/current-system/sw/share/applications` and `/etc/profiles/per-user/$USER/share/applications`.
- Prefer theme-local paths through `~/.config/quickshell/current/...`.
- New theme should be reversible by running `.config/quickshell/switch-theme.sh lotus`; the committed default may point at yahr for review/testing.
- Keep the first port simple: yahr-style bar, workspace bar, power menu, quick apps, clipboard, app launcher, calendar popup if practical.
- Use a local `Theme.qml` object rather than relying on upstream `ThemeManager` singleton.

## What's Been Tried
- Baseline: current repo only has the lotus theme. Upstream yahr was inspected in `/tmp/yahr-quickshell`; it is a full rice and should be mined selectively, not installed directly.
- Added yahr theme slice with generic `ThemeShell`, Eldritch palette, bar/workspaces, standalone widgets, app launcher, and a model-safe WorkspaceBar. Added Eldritch-style Hyprland borders/rounding/blur/shadow in `.config/hypr/theme.conf`.
- Added curated Eldritch wallpaper and `hyprpaper.conf`; scoring now includes `wallpaper_score`.
- Wired `Super+Space` to `current/AppLauncher.qml` and kept `Super+Shift+Space` as a `wofi --show drun` fallback; scoring now includes `keybind_score`.
- Added lightweight `.config/quickshell/switch-theme.sh` for lotus/yahr symlink switching; scoring now includes `switcher_score`.
- Added lotus `AppLauncher.qml` compatibility and a `Super+Shift+Space` wofi fallback.
- Added Hyprland theme snapshots and switcher support for `.config/hypr/theme.conf`; scoring now includes `hypr_switch_score`.
- Added per-theme hyprpaper snapshots and switcher support; scoring now includes `wallpaper_switch_score`.
- Replaced lotus wallpaper alias with a distinct Kanagawa wallpaper; scoring now includes `wallpaper_distinct_score`.
- Added live `hyprpaper reload` support in `switch-theme.sh`; scoring now includes `wallpaper_live_score`.
- Made yahr the coherent committed default across `current`, `theme.conf`, and `hyprpaper.conf`; scoring now includes `active_consistency_score`.
- Added `toggle-theme.sh` and bound `Super+Shift+R` to toggle via `switch-theme.sh`; scoring now includes `toggle_score`.
- Added an isolated fake-HOME runtime test for `switch-theme.sh`; scoring now includes `switcher_runtime_score`.
- Added an isolated fake-HOME runtime test for `toggle-theme.sh`; scoring now includes `toggle_runtime_score`.
- Expanded shell script syntax validation to all maintained Quickshell scripts; scoring now includes `script_syntax_score`.
- Added lotus main-shell runtime validation through generic `ThemeShell`; scoring now includes `lotus_runtime_score`.
- Fixed yahr launcher for NixOS app paths and NixOS bar branding; scoring now includes `self_contained_score`, `nixos_app_score`, and `nixos_brand_score`.
- Replaced lotus-derived yahr clipboard with a centered yahr glass panel; scoring now includes `clipboard_layout_score`.
- Increased yahr bar, app launcher, clipboard, power menu, and mako notification interface fonts to a consistent 20px baseline; scoring now includes `interface_font_score`.
- Added lotus/yahr mako notification theme snapshots and switcher support that reloads mako with the selected theme; scoring now includes `notification_switch_score`.
- Added yahr/lotus hyprlock snapshots and switcher support so the lockscreen follows the selected visual theme; scoring now includes `hyprlock_switch_score`.
- Added lightweight switchable lotus/yahr wofi fallback configs/styles with images disabled and no CSS transitions; scoring now includes `wofi_switch_score`.
- Added switchable Ghostty lotus/yahr palette snapshots and switcher support so terminal colors follow the selected theme; scoring now includes `terminal_switch_score`.
- Added a yahr-styled standalone calendar popup opened from the bar clock; scoring/runtime validation now includes `calendar_widget_score`.
- Added a yahr-styled standalone media popup opened from a bar media button, using installed `playerctl`; scoring/runtime validation now includes `media_widget_score`.
- Added a yahr-styled standalone control center opened from the bar, with Network/Bluetooth/Audio helpers and shortcuts to Media/Calendar/Power; scoring/runtime validation now includes `control_center_score`.
- Added direct Hyprland keybinds for calendar (`Super+Shift+C`), media (`Super+Shift+M`), and control center (`Super+Shift+S`) via `current/...`; scoring now includes `upstream_widget_keybind_score`.
- Added empty-state and help-text polish to the yahr launcher, clipboard, and media widgets; scoring now includes `polish_score`.
- Added a yahr-styled mako notification/history center opened from the bar, control center, and `Super+Shift+N`; scoring/runtime validation now includes `notification_center_score`.
- Upgraded the yahr control center into a richer live status dashboard for CPU, memory, battery, network, Bluetooth, audio, and media while preserving helper shortcuts; scoring now includes `live_status_score`.
- Added MPRIS album artwork support to the yahr media widget via `mpris:artUrl`, with file/URL normalization and a themed fallback glyph; scoring now includes `media_artwork_score`.
- Replaced the too-dark yahr octopus wallpaper with a brighter upstream Eldritch wallpaper, restored lotus/yahr hyprpaper snapshots, and made active hyprpaper a real yahr config instead of a stale lotus symlink; scoring now includes `wallpaper_visibility_score`.
