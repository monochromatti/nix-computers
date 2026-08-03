{ config, ... }:
let
  desktopConfig = config.nixComputers.desktop;
in
{

  config.flake.modules.nixos."host/firefly/desktop" =
    { pkgs, lib, ... }:
    {
      services.greetd = {
        enable = true;
        settings.default_session.command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --user-menu \
            --cmd niri-session
        '';
      };

      environment.etc."greetd/environments".text = ''
        niri-session
      '';

      environment.systemPackages = with pkgs; [
        marktext
        nautilus
      ];

      nixComputers.desktop.niri.settings = lib.recursiveUpdate desktopConfig.niri.settings {
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
        binds."Mod+E".spawn = "nautilus";
      };

      programs.niri.enable = true;
    };
}
