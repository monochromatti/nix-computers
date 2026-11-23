{ config, inputs, ... }:
let
  desktopConfig = config.nixComputers.desktop;
  theme = config.nixComputers.theme;
in
{
  config.perSystem =
    { pkgs, ... }:
    {
      packages.niri-stack = pkgs.callPackage ../../packages/niri-stack/package.nix { };
    };

  config.flake.modules.nixos."feature/desktop/niri" =
    {
      config,
      lib,
      pkgs,
      mpkgs,
      ...
    }:
    let
      niri = mpkgs.niri;
      user = config.nixComputers.primaryUser;
      userHome = config.users.users.${user}.home;
      userNoctaliaConfig = "${userHome}/.config/niri/noctalia.kdl";
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

            include "${userNoctaliaConfig}"
          '';
        in
        (base.apply {
          env.NIRI_CONFIG = lib.mkForce (toString mainConfig);
          patchHook = lib.mkForce ''
            chmod +w $out/share/systemd/user/niri.service
            cat >> $out/share/systemd/user/niri.service <<EOF
            [Unit]
            X-Reload-Triggers=${mainConfig}
            [Service]
            ExecReload=$out/bin/niri msg action load-config-file --path ${mainConfig}
            X-ReloadIfChanged=true
            EOF
          '';
        }).wrapper;
    in
    {
      options.nixComputers.desktop.niri.settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = desktopConfig.niri.settings;
      };

      config = {
        programs.niri.package = mkNiri config.nixComputers.desktop.niri.settings;

        # Noctalia Battery widget reads device state via UPower.
        services.upower.enable = true;
        nix.settings = {
          extra-substituters = [ "https://noctalia.cachix.org" ];
          extra-trusted-public-keys = [
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
          ];
        };
      };
    };

  config.nixComputers.desktop.niri.settings = {
    binds = {
      "Mod+T".spawn = "ghostty";
      "Mod+D".spawn = [
        "vicinae"
        "toggle"
      ];
      "Mod+L".spawn = [
        "noctalia"
        "msg"
        "session"
        "lock"
      ];
      "Mod+Shift+S".screenshot = null;
      "Super+Shift+S".screenshot = null;
      "XF86ScreenSaver".spawn = [
        "noctalia"
        "msg"
        "session"
        "lock"
      ];
      "Print".screenshot = null;
      "Shift+Print".screenshot-screen = null;
      "Ctrl+Print".screenshot-window = null;
    };

    environment.QT_QPA_PLATFORMTHEME = "qt6ct";

    cursor = {
      xcursor-theme = theme.cursor.name;
      xcursor-size = 24;
    };

    input = {
      touchpad.natural-scroll = null;
    };

    prefer-no-csd = null;

    layout = {
      gaps = 16;
      center-focused-column = "never";
      default-column-width.proportion = 0.5;
      focus-ring.off = null;
      border = {
        on = null;
        width = 1;
      };
    };

    animations.window-open = {
      duration-ms = 120;
      curve = "ease-out-quad";
    };

    window-rules = [
      {
        geometry-corner-radius = 8;
        clip-to-geometry = true;
        draw-border-with-background = false;
      }
    ];
  };

}
