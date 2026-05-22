{ pkgs, ... }:

let
  bingWallpaper = pkgs.writeShellApplication {
    name = "bing-wallpaper";

    runtimeInputs = with pkgs; [
      coreutils
      curl
      hyprpaper
      jq
      procps
      systemd
      util-linux
    ];

    text = ''
      set -euo pipefail

      market="''${BING_WALLPAPER_MARKET:-en-US}"
      monitor="''${BING_WALLPAPER_MONITOR:-eDP-1}"
      wallpaper_dir="''${BING_WALLPAPER_DIR:-$HOME/Pictures/BingWallpapers}"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/bing-wallpaper"
      hyprpaper_config="''${BING_HYPRPAPER_CONFIG:-$state_dir/hyprpaper.conf}"

      mkdir -p "$wallpaper_dir" "$state_dir" "$(dirname "$hyprpaper_config")"

      metadata=$(curl -fsSL "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=$market")
      path=$(printf '%s' "$metadata" | jq -er '.images[0].url')
      date=$(printf '%s' "$metadata" | jq -er '.images[0].startdate')
      title=$(printf '%s' "$metadata" | jq -r '.images[0].title // .images[0].copyright // "Bing wallpaper"')
      image_url="https://www.bing.com$path"
      image_path="$wallpaper_dir/bing-$date.jpg"
      current_path="$wallpaper_dir/current.jpg"

      if [[ ! -f "$image_path" ]]; then
        tmp=$(mktemp "$wallpaper_dir/.bing-$date.XXXXXX")
        curl -fL "$image_url" -o "$tmp"
        mv "$tmp" "$image_path"
      fi

      ln -sfn "$image_path" "$current_path"

      cat > "$hyprpaper_config" <<EOF
wallpaper {
  monitor = $monitor
  path = $current_path
  fit_mode = cover
}

splash = false
EOF

      if systemctl --user cat bing-hyprpaper.service >/dev/null 2>&1; then
        systemctl --user restart bing-hyprpaper.service
      else
        pkill hyprpaper >/dev/null 2>&1 || true
        setsid -f hyprpaper --config "$hyprpaper_config" >/dev/null 2>&1
      fi

      printf 'Set Bing wallpaper: %s\n' "$title"
    '';
  };
in
{
  home.packages = [
    bingWallpaper
  ];

  systemd.user.services.bing-hyprpaper = {
    Unit = {
      Description = "Hyprpaper with Bing daily wallpaper";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStartPre = "-${pkgs.procps}/bin/pkill hyprpaper";
      ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper --config %h/.local/state/bing-wallpaper/hyprpaper.conf";
      Restart = "on-failure";
    };
  };

  systemd.user.services.bing-wallpaper = {
    Unit = {
      Description = "Set Bing daily wallpaper for Hyprland";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${bingWallpaper}/bin/bing-wallpaper";
    };
  };

  systemd.user.timers.bing-wallpaper = {
    Unit.Description = "Update Bing wallpaper daily";

    Timer = {
      OnBootSec = "2min";
      OnCalendar = "daily";
      Persistent = true;
    };

    Install.WantedBy = [ "timers.target" ];
  };
}
