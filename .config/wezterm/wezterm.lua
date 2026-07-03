local wezterm = require("wezterm")
local config = wezterm.config_builder()
local is_macos = wezterm.target_triple:find("darwin") ~= nil
local home = os.getenv("HOME")

if home then
  wezterm.add_to_config_reload_watch_list(home .. "/.ssh/config")
end

local function platform_mod(macos, other)
  return is_macos and macos or other
end

config.font = wezterm.font("IoskeleyMono Nerd Font")
config.font_size = 14
config.line_height = 1.2

config.color_scheme = "Atom (Gogh)"
config.default_cursor_style = "SteadyBlock"

config.window_background_opacity = 0.85
if is_macos then
  config.macos_window_background_blur = 20
end

config.initial_rows = 34
config.initial_cols = 97

config.window_padding = {
  left = 40,
  right = 40,
  top = 40,
  bottom = 0,
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

wezterm.on("format-tab-title", function(tab)
  local pane = tab.active_pane
  local domain = pane.domain_name or ""
  local ssh_name = domain:match("^SSH:(.+)$") or domain:match("^SSHMUX:(.+)$")
  if not ssh_name and domain ~= "" and domain ~= "local" and domain ~= "localdomain" then
    ssh_name = domain
  end
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

local ssh_hosts = {
  "Sub2Api",
  "Romi-Server",
  "Romi-UR3",
  "IDT-503-TS",
  "IDT-503-Local",
  "IDT-503-TS2",
  "IDT-503-Local2",
  "aliyun",
  "eias-hpc-vla",
  "eias-hpc-vla2",
  "eias-hpc-vla3",
  "eias-hpc-cpu",
}

config.ssh_domains = {}
config.launch_menu = {}
for _, host in ipairs(ssh_hosts) do
  table.insert(config.ssh_domains, {
    name = host,
    remote_address = host,
    multiplexing = "None",
    assume_shell = "Posix",
  })
  table.insert(config.launch_menu, {
    label = host,
    domain = { DomainName = host },
  })
end

config.keys = {
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
  { key = "LeftArrow", mods = platform_mod("CMD|SHIFT", "CTRL|SHIFT"), action = wezterm.action.MoveTabRelative(-1) },
  { key = "RightArrow", mods = platform_mod("CMD|SHIFT", "CTRL|SHIFT"), action = wezterm.action.MoveTabRelative(1) },
  { key = "w", mods = platform_mod("CMD", "CTRL|SHIFT"), action = wezterm.action.CloseCurrentPane { confirm = false } },
  { key = "d", mods = platform_mod("CMD", "CTRL|SHIFT"), action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "d", mods = platform_mod("CMD|SHIFT", "CTRL|ALT"), action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
  { key = "s", mods = platform_mod("CMD|SHIFT", "CTRL|SHIFT"), action = wezterm.action.ShowLauncherArgs { flags = "FUZZY|LAUNCH_MENU_ITEMS" } },
  { key = "k", mods = platform_mod("CMD", "CTRL|SHIFT"), action = wezterm.action.SendString("clear\n") },
  { key = "N", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
}

return config
