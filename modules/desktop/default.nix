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
    };
}
