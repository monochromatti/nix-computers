{ config, inputs, ... }:
let
  theme = config.nixComputers.theme;
in
{
  flake.modules.hjem."feature/vicinae" =
    {
      pkgs,
      upkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      noctalia = "${inputs.noctalia.packages.${system}.default}/bin/noctalia";
      guardedSuspend = pkgs.writeShellApplication {
        name = "noctalia-lock-and-suspend";
        runtimeInputs = [ pkgs.jq ];
        text = ''
          exec ${pkgs.bash}/bin/bash ${./noctalia-lock-and-suspend.sh} ${noctalia}
        '';
      };
      niri = "${pkgs.niri}/bin/niri";
      systemctl = "${pkgs.systemd}/bin/systemctl";
    in
    {
      packages = [ upkgs.vicinae ];
      xdg.config.files."vicinae/settings.json" = {
        source = (pkgs.formats.json { }).generate "vicinae-settings.json" {
          theme.dark = {
            name = "nord";
            icon_theme = theme.iconTheme;
          };
          launcher_window.layer_shell.enabled = false;
          providers.power.entrypoints = {
            lock.preferences = {
              customProgram = "${noctalia} msg session lock";
              confirm = false;
            };
            suspend.preferences = {
              customProgram = "${guardedSuspend}/bin/noctalia-lock-and-suspend";
              confirm = true;
            };
            sleep.preferences = {
              customProgram = "${guardedSuspend}/bin/noctalia-lock-and-suspend";
              confirm = true;
            };
            hibernate.preferences = {
              customProgram = "${systemctl} hibernate";
              confirm = true;
            };
            reboot.preferences = {
              customProgram = "${systemctl} reboot";
              confirm = true;
            };
            "soft-reboot".preferences = {
              customProgram = "${systemctl} soft-reboot";
              confirm = true;
            };
            "power-off".preferences = {
              customProgram = "${systemctl} poweroff";
              confirm = true;
            };
            logout.preferences = {
              customProgram = "${niri} msg action quit --skip-confirmation";
              confirm = true;
            };
          };
        };
        clobber = true;
      };
      systemd.services.vicinae = {
        description = "Vicinae launcher daemon";
        enableDefaultPath = false;
        documentation = [ "https://docs.vicinae.com" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        requires = [ "dbus.socket" ];
        serviceConfig = {
          ExecStart = "${upkgs.vicinae}/bin/vicinae server --replace --config %h/.config/vicinae/settings.json";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          Restart = "always";
          RestartSec = 60;
          KillMode = "process";
        };
        wantedBy = [ "graphical-session.target" ];
      };
      xdg.config.files = {
        "systemd/user/vicinae.service".clobber = true;
        "systemd/user/graphical-session.target.wants/vicinae.service".clobber = true;
      };
    };
}
