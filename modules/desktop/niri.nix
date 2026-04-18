{ ... }:
{
  flake.desktop.niri.settings = {
    binds."Mod+T".spawn = "ghostty";

    environment.QT_QPA_PLATFORMTHEME = "qt6ct";

    input = {
      touchpad.natural-scroll = null;
      mouse.natural-scroll = null;
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

    outputs."eDP-1".scale = 1.15;
  };
}
