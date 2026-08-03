{ config, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  flake = config.flake;
  linuxNoctaliaSettingsFile =
    pkgs:
    let
      system = pkgs.stdenv.hostPlatform.system;
      noctaliaShell = "${flake.packages.${system}.noctalia-shell}/bin/noctalia-shell";
      dailyHours = inputs.daily-hours.packages.${system}.default;
      dailyHoursWorkStatus = pkgs.writeShellScript "daily-hours-work-status" ''
        state="$(${dailyHours}/bin/daily-hours work status 2>/dev/null || printf off)"
        state="''${state%%[[:space:]]*}"

        case "$state" in
          on)
            printf '%s\n' '{"text":"Work","icon":"briefcase","tooltip":"Work time tracking is on","color":"primary"}'
            ;;
          *)
            printf '%s\n' '{"text":"Off","icon":"briefcase-off","tooltip":"Work time tracking is off","color":"error"}'
            ;;
        esac
      '';
      noctaliaSettings =
        let
          base = flake.desktop.noctalia.settings;
        in
        lib.recursiveUpdate base {
          bar.widgets.right = [
            {
              id = "CustomButton";
              ipcIdentifier = "daily-hours-work";
              showIcon = true;
              icon = "briefcase";
              textCommand = dailyHoursWorkStatus;
              textIntervalMs = 3000;
              parseJson = true;
              leftClickExec = "${dailyHours}/bin/daily-hours work toggle --source noctalia && ${noctaliaShell} ipc --any-display -n call cb refresh daily-hours-work";
              leftClickUpdateText = false;
              generalTooltipText = "Toggle work time tracking";
              showExecTooltip = false;
              maxTextLength = {
                horizontal = 4;
                vertical = 0;
              };
            }
          ]
          ++ base.bar.widgets.right;
        };
    in
    # Noctalia treats a briefly missing settings file as a fresh install and
    # opens its setup panel. Keep this file regular; HM symlink replacement
    # during a switch can otherwise trigger that path.
    pkgs.writeText "noctalia-settings.json" (builtins.toJSON noctaliaSettings);
  linuxConfigFiles =
    { pkgs }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      fontSize = flake.desktop.font.size;
      noctaliaShell = "${flake.packages.${system}.noctalia-shell}/bin/noctalia-shell";
      niri = "${pkgs.niri}/bin/niri";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      home = flake.lib.users.monochromatti.home.linux;
    in
    {
      "vicinae/settings.json".source = (pkgs.formats.json { }).generate "vicinae-settings.json" {
        theme.dark = {
          name = "nord";
          icon_theme = "Papirus-Dark";
        };
        launcher_window.layer_shell.enabled = false;
        providers.power.entrypoints = {
          lock.preferences = {
            customProgram = "${noctaliaShell} ipc --any-display -n call sessionMenu lock";
            confirm = false;
          };
          suspend.preferences = {
            customProgram = "${noctaliaShell} ipc --any-display -n call sessionMenu lockAndSuspend";
            confirm = true;
          };
          sleep.preferences = {
            customProgram = "${noctaliaShell} ipc --any-display -n call sessionMenu lockAndSuspend";
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
          soft-reboot.preferences = {
            customProgram = "${systemctl} soft-reboot";
            confirm = true;
          };
          power-off.preferences = {
            customProgram = "${systemctl} poweroff";
            confirm = true;
          };
          logout.preferences = {
            customProgram = "${niri} msg action quit --skip-confirmation";
            confirm = true;
          };
        };
      };
      "qt6ct/qt6ct.conf".source = pkgs.writeText "qt6ct.conf" ''
        [Appearance]
        color_scheme_path=${home}/.config/qt6ct/colors/noctalia.conf
        custom_palette=true
        icon_theme=Papirus-Dark
        style=Fusion

        [Fonts]
        fixed="JetBrains Mono,${toString fontSize},-1,5,400,0,0,0,0,0"
        general="Inter,${toString fontSize},-1,5,400,0,0,0,0,0"
      '';
    };
  gtkConfigFiles =
    { pkgs }:
    {
      files = {
        ".gtkrc-2.0".text = ''
          gtk-cursor-theme-name = "Adwaita"
          gtk-cursor-theme-size = 32
          gtk-font-name = "Inter 12"
          gtk-icon-theme-name = "Papirus-Dark"
          gtk-theme-name = "adw-gtk3-dark"

        '';
        ".Xresources".text = ''
          Xcursor.size: 32
          Xcursor.theme: Adwaita
        '';
        ".icons/Adwaita".source = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita";
        ".icons/default/index.theme".text = ''
          [Icon Theme]
          Name=Default
          Comment=Default Cursor Theme
          Inherits=Adwaita
        '';
      };
      xdgConfig = {
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-cursor-theme-name=Adwaita
          gtk-cursor-theme-size=32
          gtk-font-name=Inter 12
          gtk-icon-theme-name=Papirus-Dark
          gtk-theme-name=adw-gtk3-dark
        '';
        "gtk-4.0/settings.ini".text = ''
          [Settings]
          gtk-cursor-theme-name=Adwaita
          gtk-cursor-theme-size=32
          gtk-font-name=Inter 12
          gtk-icon-theme-name=Papirus-Dark
          gtk-theme-name=adw-gtk3-dark
        '';
        "gtk-4.0/gtk.css".text = ''
          /**
           * GTK 4 reads the theme configured by gtk-theme-name, but ignores it.
           * It does however respect user CSS, so import the theme from here.
          **/
          @import url("file://${pkgs.adw-gtk3}/share/themes/adw-gtk3-dark/gtk-4.0/gtk.css");
        '';
        "fontconfig/conf.d/10-hm-fonts.conf".text = ''
          <?xml version='1.0'?>

          <!-- Generated by Hjem. -->

          <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
          <fontconfig>
            <description>Add fonts in the Hjem user profile</description>
            <dir>/etc/profiles/per-user/monochromatti/lib/X11/fonts</dir>
            <dir>/etc/profiles/per-user/monochromatti/share/fonts</dir>
          </fontconfig>
        '';
        "fontconfig/conf.d/10-hm-rendering.conf".text = ''
          <?xml version='1.0'?>

          <!-- Generated by Hjem. -->

          <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
          <fontconfig>
          </fontconfig>
        '';
        "fontconfig/conf.d/52-hm-default-fonts.conf".text = ''
          <?xml version='1.0'?>

          <!-- Generated by Hjem. -->

          <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
          <fontconfig>
          </fontconfig>
        '';
      };
      xdgData = {
        "icons/Adwaita".source = "${pkgs.adwaita-icon-theme}/share/icons/Adwaita";
        "icons/default/index.theme".text = ''
          [Icon Theme]
          Name=Default
          Comment=Default Cursor Theme
          Inherits=Adwaita
        '';
      };
    };
in
{
  options.flake.linuxNoctaliaSettingsFile = lib.mkOption {
    type = lib.types.raw;
  };
  options.flake.linuxConfigFiles = lib.mkOption {
    type = lib.types.raw;
  };
  options.flake.gtkConfigFiles = lib.mkOption {
    type = lib.types.raw;
  };
  config.flake.linuxNoctaliaSettingsFile = linuxNoctaliaSettingsFile;
  config.flake.linuxConfigFiles = linuxConfigFiles;
  config.flake.gtkConfigFiles = gtkConfigFiles;

  config.flake.userPackageGroups.gtk = pkgs: [
    pkgs.adw-gtk3
    pkgs.papirus-icon-theme
    pkgs.adwaita-icon-theme
  ];

  config.flake.userPackageGroups.linux =
    { pkgs, upkgs }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    [
      flake.packages.${system}.noctalia-shell
      pkgs.nwg-look
      pkgs.qt6Packages.qt6ct
      upkgs.vicinae
    ];

  config.flake.modules.homeManager.linux =
    { ... }:
    {
      xdg.enable = true;
    };
}
