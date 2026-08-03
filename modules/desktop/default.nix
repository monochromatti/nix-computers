{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  options.nixComputers.desktop = lib.mkOption {
    type = lib.types.submodule {
      options = {
        niri.settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
        noctalia = {
          settings = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          wallpaper = lib.mkOption {
            type = lib.types.path;
            default = ../../dotfiles/wallpapers/aishot-4712.jpg;
          };
        };
      };
    };
    default = { };
  };

  config.flake.modules.nixos."feature/desktop/daily-hours" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dailyHours = inputs.daily-hours.packages.${pkgs.stdenv.hostPlatform.system}.default;
      user = config.nixComputers.primaryUser;
      home = if user == null then null else lib.attrByPath [ "users" "users" user "home" ] null config;
    in
    lib.mkIf (user != null && home != null) {
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
