{ ... }:
{
  flake.desktop.niri.settings = {
    binds = {
      "Mod+T".spawn = "ghostty";
      "Mod+D".spawn = "walker";
    };

    environment.QT_QPA_PLATFORMTHEME = "qt6ct";

    cursor = {
      xcursor-theme = "Adwaita";
      xcursor-size = 24;
    };

    input = {
      touchpad.natural-scroll = null;
    };

    layout = {
      gaps = 12;
      focus-ring.width = 2;
    };

    window-rules = [
      {
        geometry-corner-radius = 12;
        clip-to-geometry = true;
      }
    ];

    outputs = {
      "eDP-1" = {
        scale = 1.15;
        position._attrs = {
          x = 1725;
          y = 0;
        };
      };

      "DP-1" = {
        mode = "5120x1440@29.979";
        scale = 1;
        position._attrs = {
          x = 0;
          y = -1440;
        };
      };
    };
  };
}
