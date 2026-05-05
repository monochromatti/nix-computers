{ inputs, self, ... }:
let
  opacity = 0.95;
in
{
  flake.desktop.opacity = opacity;

  perSystem =
    { pkgs, ... }:
    {
      packages.niri-stack = pkgs.callPackage ../../packages/niri-stack/package.nix { };
    };

  flake.modules.nixos.niri =
    {
      config,
      lib,
      pkgs,
      mpkgs,
      ...
    }:
    let
      niri = mpkgs.niri;
      userNoctaliaConfig = "${self.lib.users.monochromatti.home.linux}/.config/niri/noctalia.kdl";
      defaultConfig = pkgs.runCommand "niri-default-config.kdl" { } ''
        cp ${niri.src}/resources/default-config.kdl $out
        substituteInPlace $out \
          --replace-fail 'spawn-at-startup "waybar"' '// spawn-at-startup "waybar"'
      '';
      mkNiri =
        settings:
        let
          base = inputs.wrappers.wrapperModules.niri.apply {
            inherit pkgs settings;
            package = lib.mkForce niri;
          };
          mainConfig = pkgs.writeText "niri-main-config.kdl" ''
            include "${defaultConfig}"
            include "${base."config.kdl".path}"

            layout {
              background-color "transparent"
            }

            blur {
              passes 2
              offset 3.0
              noise 0.03
              saturation 1.0
            }

            window-rule {
              match app-id="^com\\.mitchellh\\.ghostty$"
              draw-border-with-background false

              background-effect {
                blur true
              }
            }

            window-rule {
              match app-id="^dev\\.zed\\.Zed$"
              draw-border-with-background false

              background-effect {
                blur true
              }
            }

            layer-rule {
              match layer="top"
              match layer="overlay"

              background-effect {
                xray false
              }
            }

            layer-rule {
              match namespace="^noctalia-wallpaper*"
              place-within-backdrop true
            }

            layer-rule {
              match namespace="^noctalia-overview*"
              place-within-backdrop true
            }

            include "${userNoctaliaConfig}"
          '';
        in
        (base.apply {
          env.NIRI_CONFIG = lib.mkForce (toString mainConfig);
        }).wrapper;
    in
    {
      options.midgard.niri.settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = self.desktop.niri.settings;
      };

      config.programs.niri.package = mkNiri config.midgard.niri.settings;
    };

  flake.desktop.niri.settings = {
    binds = {
      "Mod+T".spawn = "ghostty";
      "Mod+D".spawn = [
        "vicinae"
        "toggle"
      ];
      "Mod+L".spawn = [
        "noctalia-shell"
        "ipc"
        "--any-display"
        "-n"
        "call"
        "sessionMenu"
        "lock"
      ];
      "Mod+Shift+S".screenshot = null;
      "Super+Shift+S".screenshot = null;
      "XF86ScreenSaver".spawn = [
        "noctalia-shell"
        "ipc"
        "--any-display"
        "-n"
        "call"
        "sessionMenu"
        "lock"
      ];
      "Print".screenshot = null;
      "Shift+Print".screenshot-screen = null;
      "Ctrl+Print".screenshot-window = null;
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
  };

  flake.desktop.niri.hostSettings.firefly = {
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
