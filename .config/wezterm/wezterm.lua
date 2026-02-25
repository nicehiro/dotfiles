local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.font = wezterm.font("GeistMono Nerd Font")
config.font_size = 16
config.line_height = 1.2

config.color_scheme = "Atom (Gogh)"
config.default_cursor_style = "SteadyBlock"

config.window_background_opacity = 0.85
config.macos_window_background_blur = 20

config.initial_rows = 34
config.initial_cols = 97

config.window_padding = {
  left = 40,
  right = 40,
  top = 40,
  bottom = 40,
}

config.window_decorations = "RESIZE"
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = false

config.colors = {
  tab_bar = {
    background = "rgba(0,0,0,0)",
    active_tab = {
      bg_color = "#ca9ee6",
      fg_color = "#303446",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "rgba(0,0,0,0)",
      fg_color = "#808080",
    },
    inactive_tab_hover = {
      bg_color = "#414559",
      fg_color = "#c6d0f5",
    },
  },
}

-- Clean tab titles: process name, or remote host for SSH
wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local domain = pane.domain_name or ""
  local ssh_name = domain:match("^SSH:(.+)$") or domain:match("^SSHMUX:(.+)$")
  if ssh_name then
    return string.format("  %s  ", ssh_name)
  end
  local process = pane.foreground_process_name:match("([^/]+)$") or ""
  if process == "ssh" then
    local host = pane.title:match("([%w._-]+)%s*$") or "ssh"
    return string.format("  %s  ", host)
  end
  return string.format("  %s  ", process ~= "" and process or "shell")
end)
config.hide_mouse_cursor_when_typing = true
config.mouse_wheel_scrolls_tabs = false
config.scroll_to_bottom_on_input = true

config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

config.ssh_domains = {
  { name = "aliyun", remote_address = "8.153.103.186", username = "root" },
  { name = "eias-hpc-vla", remote_address = "hpc.eias.ac.cn:40033", username = "root" },
}

config.keys = {
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
  { key = "w", mods = "CMD", action = wezterm.action.CloseCurrentPane { confirm = false } },
  { key = "d", mods = "CMD", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "d", mods = "CMD|SHIFT", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "k", mods = "CMD", action = wezterm.action.SendString("clear\n") },
}

return config
