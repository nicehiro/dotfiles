{ pkgs, ... }:

let
  wallpaper = "/home/fangyuan/Pictures/Omarchy/kanagawa-lotus/1-kanagawa.jpg";
in
{
  home.packages = with pkgs; [
    cliphist
    libnotify
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$browser" = "firefox";
      "$fileManager" = "nautilus --new-window";

      monitor = [
        ",preferred,auto,1"
      ];

      exec-once = [
        "quickshell --no-duplicate"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "GDK_BACKEND,wayland,x11"
        "QT_QPA_PLATFORM,wayland;xcb"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
      ];

      input = {
        kb_layout = "us";
        kb_options = "ctrl:nocaps,altwin:swap_alt_win";
        follow_mouse = 1;

        touchpad = {
          natural_scroll = false;
        };
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(61afefcc)";
        "col.inactive_border" = "rgba(3b414dcc)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 4;
        shadow.enabled = false;
        blur = {
          enabled = true;
          size = 5;
          passes = 2;
        };
      };

      animations.enabled = true;

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, F, exec, $fileManager"
        "$mod, Space, exec, wofi --show drun"
        "$mod, Tab, exec, quickshell -p ~/.config/quickshell/themes/lotus/QuickApps.qml"
        "$mod, W, killactive"
        "$mod, Backspace, killactive"
        "$mod, Escape, exec, hyprlock"
        "$mod SHIFT, Escape, exit"

        "$mod, J, togglesplit"
        "$mod, T, togglefloating"
        "$mod SHIFT, Plus, fullscreen"

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        "$mod SHIFT, left, swapwindow, l"
        "$mod SHIFT, right, swapwindow, r"
        "$mod SHIFT, up, swapwindow, u"
        "$mod SHIFT, down, swapwindow, d"

        "$mod, minus, resizeactive, -100 0"
        "$mod, equal, resizeactive, 100 0"
        "$mod SHIFT, minus, resizeactive, 0 -100"
        "$mod SHIFT, equal, resizeactive, 0 100"

        ", PRINT, exec, hyprshot -m region"
        "SHIFT, PRINT, exec, hyprshot -m window"
        "CTRL, PRINT, exec, hyprshot -m output"
        "$mod, PRINT, exec, hyprpicker -a"
        "$mod, V, exec, quickshell -p ~/.config/quickshell/themes/lotus/Clipboard.qml"
        "$mod SHIFT, V, exec, cliphist wipe && notify-send 'Clipboard history cleared'"
        "$mod SHIFT, P, exec, quickshell -p ~/.config/quickshell/themes/lotus/PowerMenu.qml"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];


    };

    extraConfig = ''
      windowrule {
        name = suppress-maximize-events
        match:class = .*
        suppress_event = maximize
      }

      windowrule {
        name = float-settings-windows
        match:class = ^(org.pulseaudio.pavucontrol|blueman-manager)$
        float = yes
      }
    '';
  };

  programs.wofi = {
    enable = true;
    settings = {
      width = 900;
      height = 640;
      location = "center";
      show = "drun";
      prompt = "Search";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 40;
      gtk_dark = false;
    };

    style = ''
      * {
        font-family: "IoskeleyMono Nerd Font", "Symbols Nerd Font", serif;
        font-size: 20px;
      }

      window {
        margin: 0;
        padding: 28px;
        border: 1px solid rgba(84, 84, 100, 0.22);
        border-radius: 0;
        background-color: rgba(241, 233, 210, 0.96);
      }

      #outer-box,
      #inner-box,
      #scroll {
        margin: 0;
        padding: 0;
        border: none;
        background-color: transparent;
      }

      #input {
        margin: 0 0 20px 0;
        padding: 16px 18px;
        border: 1px solid rgba(84, 84, 100, 0.22);
        border-radius: 0;
        background-color: #e6dcc0;
        color: #545464;
      }

      #input:focus {
        border-color: #4d699b;
        box-shadow: none;
      }

      #entry {
        padding: 13px 16px;
        border: 1px solid transparent;
        border-radius: 0;
        background-color: transparent;
      }

      #entry:selected {
        border-color: rgba(200, 64, 83, 0.55);
        background-color: #545464;
      }

      #entry:selected #text {
        color: #f1e9d2;
      }

      #entry:selected image {
        opacity: 0.92;
      }

      #text {
        margin: 0 12px;
        color: #545464;
      }

      #entry image {
        margin-right: 14px;
      }

      scrollbar {
        border: none;
        background-color: transparent;
      }

      scrollbar slider {
        min-height: 48px;
        border: none;
        border-radius: 0;
        background-color: rgba(84, 84, 100, 0.28);
      }
    '';
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };

      background = {
        monitor = "";
        path = wallpaper;
        blur_passes = 2;
        brightness = 0.55;
      };

      input-field = {
        monitor = "";
        size = "360, 56";
        position = "0, -40";
        halign = "center";
        valign = "center";
        inner_color = "rgba(26, 27, 38, 0.85)";
        outer_color = "rgba(122, 162, 247, 1.0)";
        font_color = "rgb(192, 202, 245)";
        placeholder_text = "Password";
        outline_thickness = 2;
        rounding = 8;
        fade_on_empty = false;
      };
    };
  };

  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      layer = "overlay";
      width = 420;
      height = 120;
      margin = 12;
      padding = "12";
      border-size = 2;
      border-radius = 8;

      background-color = "#282c34ee";
      text-color = "#dce0e5ff";
      border-color = "#61afefff";
      progress-color = "over #98c379ff";

      font = "IoskeleyMono Nerd Font 11";
      default-timeout = 5000;
      ignore-timeout = false;
      max-visible = 5;
      sort = "-time";
      group-by = "app-name";

      icons = true;
      max-icon-size = 48;
      markup = true;
      actions = true;
      format = "<b>%s</b>\\n%b";
    };

    extraConfig = ''
      [urgency=low]
      border-color=#3b414dff
      default-timeout=3000

      [urgency=critical]
      border-color=#e06c75ff
      default-timeout=0
    '';
  };
  services.hyprpaper = {
    enable = true;
    settings = {
      wallpaper = [
        {
          monitor = "eDP-1";
          path = wallpaper;
          fit_mode = "cover";
        }
      ];
    };
  };
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
