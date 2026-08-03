{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.nixos.firefly.imports = [
    (
      {
        pkgs,
        upkgs,
        lib,
        ...
      }:
      let
        generatedSettingsFile = flake.linuxNoctaliaSettingsFile pkgs;
        wallpaperFile = pkgs.writeText "noctalia-wallpapers.json" ''
          {"wallpapers":{},"defaultWallpaper":"${toString ../../../dotfiles/wallpapers/aishot-4712.jpg}","usedRandomWallpapers":{}}
        '';
        noctaliaSettingsSetup = pkgs.writeShellApplication {
          name = "noctalia-settings-setup";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.jq
          ];
          text = ''
            config_dir=/home/monochromatti/.config/noctalia
            settings_file="$config_dir/settings.json"
            tmp_file=""

            cleanup() {
              if [ -n "$tmp_file" ]; then
                rm -f "$tmp_file"
              fi
            }
            trap cleanup EXIT

            install -d -m 0755 "$config_dir"
            tmp_file=$(mktemp "$config_dir/.settings.json.XXXXXX")
            install -m 0644 "${generatedSettingsFile}" "$tmp_file"
            jq -e . "$tmp_file" >/dev/null
            mv -fT "$tmp_file" "$settings_file"
            tmp_file=""

            test -f "$settings_file"
            test ! -L "$settings_file"
                test -w "$settings_file"
          '';
        };
        noctaliaWallpaperCacheSetup = pkgs.writeShellApplication {
          name = "noctalia-wallpaper-cache-setup";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.jq
          ];
          text = ''
            cache_dir=/home/monochromatti/.cache/noctalia
            cache_file="$cache_dir/wallpapers.json"
            tmp_file=""

            cleanup() {
              if [ -n "$tmp_file" ]; then
                rm -f "$tmp_file"
              fi
            }
            trap cleanup EXIT

            install -d -m 0755 "$cache_dir"
            tmp_file=$(mktemp "$cache_dir/.wallpapers.json.XXXXXX")
            install -m 0644 "${wallpaperFile}" "$tmp_file"
            jq -e . "$tmp_file" >/dev/null
            mv -fT "$tmp_file" "$cache_file"
            tmp_file=""

            test -f "$cache_file"
            test ! -L "$cache_file"
            test -w "$cache_file"
          '';
        };
        noctaliaThemeStubs = pkgs.writeShellApplication {
          name = "noctalia-theme-stubs";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            ensure_directory() {
              if [ -L "$1" ]; then
                printf 'Refusing symlink directory: %s\n' "$1" >&2
                exit 1
              fi
              mkdir -p "$1"
              if [ ! -d "$1" ] || [ -L "$1" ]; then
                printf 'Expected regular directory: %s\n' "$1" >&2
                exit 1
              fi
            }

            ensure_file() {
              if [ -L "$1" ]; then
                printf 'Refusing symlink file: %s\n' "$1" >&2
                exit 1
              fi
              if [ -e "$1" ] && [ ! -f "$1" ]; then
                printf 'Expected regular file: %s\n' "$1" >&2
                exit 1
              fi
            }

            ensure_directory "$HOME/.config"
            ensure_directory "$HOME/.config/niri"
            ensure_directory "$HOME/.config/qt6ct"
            ensure_directory "$HOME/.config/qt6ct/colors"

            niri_theme="$HOME/.config/niri/noctalia.kdl"
            ensure_file "$niri_theme"
            if [ ! -e "$niri_theme" ]; then
              printf '%s\n' '// populated by Noctalia' > "$niri_theme"
            fi

            qt_theme="$HOME/.config/qt6ct/colors/noctalia.conf"
            ensure_file "$qt_theme"
            if [ ! -e "$qt_theme" ]; then
              : > "$qt_theme"
            fi
          '';
        };
      in
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

        hjem.users.monochromatti.systemd.services.noctalia-settings-setup = {
          description = "Install Noctalia settings";
          before = [ "noctalia.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${noctaliaSettingsSetup}/bin/noctalia-settings-setup";
          };
          restartTriggers = [ generatedSettingsFile ];
        };

        hjem.users.monochromatti.systemd.services.noctalia-theme-stubs = {
          description = "Create Noctalia theme stub files";
          before = [ "noctalia.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${noctaliaThemeStubs}/bin/noctalia-theme-stubs";
          };
        };

        hjem.users.monochromatti.systemd.services.noctalia-wallpaper-cache = {
          description = "Install Noctalia wallpaper cache";
          # Run before Noctalia once per user-manager lifetime, and rerun while
          # active when wallpaper payload changes. Do not rewrite cache on each
          # Noctalia restart.
          before = [ "noctalia.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${noctaliaWallpaperCacheSetup}/bin/noctalia-wallpaper-cache-setup";
          };
          restartTriggers = [ wallpaperFile ];
        };

        hjem.users.monochromatti.systemd.services.noctalia = {
          description = "Noctalia shell";
          path = [
            pkgs.bash
            pkgs.coreutils
            pkgs.systemd
            pkgs.procps
            pkgs.curl
            pkgs.fontconfig
          ];
          partOf = [ "graphical-session.target" ];
          requires = [
            "noctalia-settings-setup.service"
            "noctalia-theme-stubs.service"
            "noctalia-wallpaper-cache.service"
          ];
          after = [
            "graphical-session.target"
            "noctalia-settings-setup.service"
            "noctalia-theme-stubs.service"
            "noctalia-wallpaper-cache.service"
          ];
          serviceConfig = {
            ExecStart = "${
              flake.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell
            }/bin/noctalia-shell";
            Restart = "on-failure";
            RestartSec = 2;
          };
          restartTriggers = [ (pkgs.writeText "noctalia-settings-hjem-enabled" "1") ];
          wantedBy = [ "graphical-session.target" ];
        };

        hjem.users.monochromatti.systemd.services.vicinae = {
          description = "Vicinae launcher daemon";
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

        hjem.users.monochromatti.systemd.services.overskride = {
          description = "Overskride Bluetooth manager";
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.overskride}/bin/overskride";
            Restart = "on-failure";
            RestartSec = 2;
          };
          wantedBy = [ "graphical-session.target" ];
        };

        hjem.users.monochromatti.xdg.config.files."systemd/user/noctalia-settings-setup.service".clobber =
          true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/noctalia-theme-stubs.service".clobber =
          true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/noctalia-wallpaper-cache.service".clobber =
          true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/noctalia.service".clobber = true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/graphical-session.target.wants/noctalia.service".clobber =
          true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/vicinae.service".clobber = true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/graphical-session.target.wants/vicinae.service".clobber =
          true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/overskride.service".clobber = true;
        hjem.users.monochromatti.xdg.config.files."systemd/user/graphical-session.target.wants/overskride.service".clobber =
          true;
      }
    )
  ];
}
