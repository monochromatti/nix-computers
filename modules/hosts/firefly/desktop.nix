{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.nixos.firefly.imports = [
    (
      {
        pkgs,
        lib,
        ...
      }:
      {
        services.greetd = {
          enable = true;
          settings = {
            default_session.command = ''
              ${pkgs.tuigreet}/bin/tuigreet \
                --time \
                --asterisks \
                --user-menu \
                --cmd niri-session
            '';
          };
        };

        environment.etc."greetd/environments".text = ''
          niri-session
        '';

        environment.systemPackages = with pkgs; [
          marktext
          nautilus
          overskride
        ];

        midgard.niri.settings = lib.recursiveUpdate flake.desktop.niri.settings (
          lib.recursiveUpdate flake.desktop.niri.hostSettings.firefly {
            binds."Mod+E".spawn = "nautilus";
          }
        );

        programs.niri.enable = true;

        home-manager.users.monochromatti.systemd.user.services.overskride = {
          Unit = {
            Description = "Overskride Bluetooth manager";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${pkgs.overskride}/bin/overskride";
            Restart = "on-failure";
            RestartSec = 2;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      }
    )
  ];
}
