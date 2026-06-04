{ config, ... }:
let
  flake = config.flake;
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.linear-notify = pkgs.callPackage ../packages/linear-notify/package.nix { };
    };

  flake.modules.nixos.linear-notify =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.linear-notify;
      package = cfg.package;
      onlyConfiguredUser = pkgs.writeShellScript "linear-notify-only-user" ''
        [ "$1" = ${lib.escapeShellArg cfg.user} ]
      '';
      optionalFlag = cond: flag: lib.optionalString cond " ${flag}";
      execStart =
        lib.concatStringsSep " " (
          [
            "${package}/bin/linear-notify"
            "--token-file"
            (lib.escapeShellArg cfg.tokenFile)
            "--interval"
            (toString cfg.intervalSeconds)
            "--page-size"
            (toString cfg.pageSize)
            "--max-seen-ids"
            (toString cfg.maxSeenIds)
            "--max-backoff-seconds"
            (toString cfg.maxBackoffSeconds)
            "--request-timeout"
            (toString cfg.requestTimeoutSeconds)
            "--startup-secret-timeout"
            (toString cfg.startupSecretTimeoutSeconds)
            "--notify-send"
            "${pkgs.libnotify}/bin/notify-send"
            "--xdg-open"
            "${pkgs.xdg-utils}/bin/xdg-open"
            "--action-expire-time-ms"
            (toString cfg.actionExpireTimeMs)
            "--action-wait-timeout"
            (toString cfg.actionWaitTimeoutSeconds)
          ]
          ++ lib.optionals (cfg.stateFile != null) [
            "--state-file"
            (lib.escapeShellArg cfg.stateFile)
          ]
        )
        + optionalFlag cfg.notifyExistingOnFirstRun "--notify-existing-on-first-run"
        + optionalFlag cfg.enableActions "--enable-actions";
    in
    {
      options.services.linear-notify = {
        enable = lib.mkEnableOption "Linear desktop notification daemon";
        package = lib.mkOption {
          type = lib.types.package;
          default = flake.packages.${pkgs.stdenv.hostPlatform.system}.linear-notify;
          defaultText = lib.literalExpression "flake.packages.\${system}.linear-notify";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "monochromatti";
        };
        tokenFile = lib.mkOption {
          type = lib.types.path;
          default = "/run/secrets/linear-api-key";
        };
        intervalSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 45;
        };
        pageSize = lib.mkOption {
          type = lib.types.ints.positive;
          default = 50;
        };
        maxSeenIds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1000;
        };
        maxBackoffSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 300;
        };
        requestTimeoutSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 15;
        };
        startupSecretTimeoutSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 60;
        };
        notifyExistingOnFirstRun = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        enableActions = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        actionExpireTimeMs = lib.mkOption {
          type = lib.types.ints.positive;
          default = 15000;
        };
        actionWaitTimeoutSeconds = lib.mkOption {
          type = lib.types.ints.positive;
          default = 20;
        };
        stateFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.user != "";
            message = "services.linear-notify.user must not be empty";
          }
          {
            assertion = cfg.intervalSeconds >= 5;
            message = "services.linear-notify.intervalSeconds must be >= 5";
          }
          {
            assertion = cfg.pageSize > 0;
            message = "services.linear-notify.pageSize must be > 0";
          }
          {
            assertion = cfg.maxSeenIds > 0;
            message = "services.linear-notify.maxSeenIds must be > 0";
          }
          {
            assertion = cfg.requestTimeoutSeconds > 0;
            message = "services.linear-notify.requestTimeoutSeconds must be > 0";
          }
        ];

        environment.systemPackages = [ package ];

        systemd.user.services.linear-notify = {
          description = "Linear desktop notification daemon";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wants = [ "dbus.socket" ];
          after = [
            "graphical-session.target"
            "dbus.socket"
          ];
          serviceConfig = {
            Type = "simple";
            ExecCondition = "${onlyConfiguredUser} %u";
            ExecStart = execStart;
            Restart = "always";
            RestartSec = "30s";
            Slice = "session.slice";
          };
        };
      };
    };
}
