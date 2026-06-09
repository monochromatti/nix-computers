{ config, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  flake = config.flake;
in
{
  options.flake.desktop = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;
      options = {
        opacity = lib.mkOption {
          type = lib.types.float;
        };

        font.size = lib.mkOption {
          type = lib.types.ints.positive;
          default = 12;
        };
      };
    };
    default = { };
  };

  config.flake.modules.nixos.dailyHours =
    { pkgs, ... }:
    let
      dailyHours = inputs.daily-hours.packages.${pkgs.stdenv.hostPlatform.system}.default;
      user = "monochromatti";
      home = flake.lib.users.${user}.home.linux;
    in
    {
      systemd.services.daily-hours-work-session = {
        description = "daily-hours work session marker";
        wantedBy = [ "graphical.target" ];
        after = [ "graphical.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = user;
          Environment = [
            "HOME=${home}"
            "XDG_STATE_HOME=${home}/.local/state"
          ];
          ExecStart = "${dailyHours}/bin/daily-hours work on --source startup";
          ExecStop = "${dailyHours}/bin/daily-hours work off --source shutdown";
        };
      };

      environment.etc."systemd/system-sleep/daily-hours".source =
        pkgs.writeShellScript "daily-hours-system-sleep" ''
          daily_hours=${dailyHours}/bin/daily-hours
          run_as_user="${pkgs.util-linux}/bin/runuser -u ${user} --"

          case "$1" in
            pre)
              $run_as_user env HOME=${home} XDG_STATE_HOME=${home}/.local/state \
                "$daily_hours" work off --source suspend
              ;;
            post)
              $run_as_user env HOME=${home} XDG_STATE_HOME=${home}/.local/state \
                "$daily_hours" work on --source resume
              ;;
          esac
        '';
    };
}
