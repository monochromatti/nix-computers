{ config, inputs, ... }:
let
  flake = config.flake;
  desktopConfig = config.nixComputers.desktop;
  theme = config.nixComputers.theme;
  lib = inputs.nixpkgs.lib;
in
{
  config.perSystem =
    { pkgs, upkgs, ... }:
    {
      packages = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        noctalia-shell =
          let
            noctaliaQsFixed = upkgs.noctalia-qs.overrideAttrs (_: rec {
              version = "0.0.12";
              src = pkgs.fetchFromGitHub {
                owner = "noctalia-dev";
                repo = "noctalia-qs";
                tag = "v${version}";
                hash = "sha256-79JP2QTdvp1jg7HGxAW+xzhzhLnlKUi8yGXq9nDCeH0=";
              };
              patches = [ ];
            });
          in
          inputs.wrappers.lib.wrapPackage {
            inherit pkgs;
            package = upkgs.noctalia-shell.override { noctalia-qs = noctaliaQsFixed; };
          };
      };
    };

  config.nixComputers.desktop.noctalia.settings = {
    settingsVersion = 59;
    general = {
      radiusRatio = 1.0;
      iRadiusRatio = 1.0;
    };
    bar = {
      showCapsule = false;
      backgroundOpacity = 0.9;
      frameRadius = 12;
      widgetSpacing = 6;
      widgets = {
        left = [
          {
            id = "CustomButton";
            icon = "rocket";
            leftClickExec = "vicinae toggle";
            generalTooltipText = "Open launcher";
          }
          { id = "Clock"; }
          { id = "SystemMonitor"; }
          { id = "ActiveWindow"; }
          { id = "MediaMini"; }
        ];
        center = [ { id = "Workspace"; } ];
        right = [
          { id = "Tray"; }
          { id = "NotificationHistory"; }
          { id = "Battery"; }
          { id = "Volume"; }
          { id = "Brightness"; }
          { id = "ControlCenter"; }
        ];
      };
    };
    ui = {
      fontDefault = theme.font.sans;
      fontFixed = theme.font.fixed;
      panelBackgroundOpacity = 0.92;
    };
    location.weatherEnabled = false;
    dock.enabled = false;
    wallpaper = {
      enabled = true;
      overviewEnabled = false;
      directory = toString ../../dotfiles/wallpapers;
      setWallpaperOnAllMonitors = true;
      linkLightAndDarkWallpapers = true;
      fillMode = "crop";
      useOriginalImages = true;
      useSolidColor = false;
      skipStartupTransition = true;
      automationEnabled = false;
      sortOrder = "name";
    };
    colorSchemes = {
      darkMode = true;
      useWallpaperColors = false;
      predefinedScheme = theme.colorScheme;
      syncGsettings = true;
    };
    templates.activeTemplates =
      map
        (id: {
          inherit id;
          enabled = true;
        })
        [
          "ghostty"
          "gtk"
          "qt"
          "kcolorscheme"
          "niri"
          "vicinae"
          "zed"
          "zenBrowser"
        ];
  };

  config.flake.modules.hjem."feature/noctalia" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      noctaliaShell = "${flake.packages.${system}.noctalia-shell}/bin/noctalia-shell";
      dailyHours = inputs.daily-hours.packages.${system}.default;
      dailyHoursWorkStatus = pkgs.writeShellScript "daily-hours-work-status" ''
        state="$(${dailyHours}/bin/daily-hours work status 2>/dev/null || printf off)"
        state="''${state%%[[:space:]]*}"
        case "$state" in
          on) printf '%s\n' '{"text":"Work","icon":"briefcase","tooltip":"Work time tracking is on","color":"primary"}' ;;
          *) printf '%s\n' '{"text":"Off","icon":"briefcase-off","tooltip":"Work time tracking is off","color":"error"}' ;;
        esac
      '';
      settingsFile =
        let
          base = desktopConfig.noctalia.settings;
          settings = lib.recursiveUpdate base {
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
        pkgs.writeText "noctalia-settings.json" (builtins.toJSON settings);
      wallpaperFile = pkgs.writeText "noctalia-wallpapers.json" ''
        {"wallpapers":{},"defaultWallpaper":"${toString desktopConfig.noctalia.wallpaper}","usedRandomWallpapers":{}}
      '';
      safeDirectoryLogic = ''
        ensure_directory() { if [ -L "$1" ]; then printf 'Refusing symlink directory: %s\n' "$1" >&2; exit 1; fi; if [ -e "$1" ] && [ ! -d "$1" ]; then printf 'Expected directory: %s\n' "$1" >&2; exit 1; fi; mkdir -p "$1"; }
      '';
      settingsSetup = pkgs.writeShellApplication {
        name = "noctalia-settings-setup";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
              ${safeDirectoryLogic}
              config_dir="$HOME/.config/noctalia"; settings_file="$config_dir/settings.json"; tmp_file=""
              cleanup() { if [ -n "$tmp_file" ]; then rm -f "$tmp_file"; fi; }; trap cleanup EXIT
              ensure_directory "$HOME"; ensure_directory "$HOME/.config"; ensure_directory "$config_dir"; tmp_file=$(mktemp "$config_dir/.settings.json.XXXXXX")
          install -m 0644 "${settingsFile}" "$tmp_file"; jq -e . "$tmp_file" >/dev/null; mv -fT "$tmp_file" "$settings_file"; tmp_file=""
          test -f "$settings_file"; test ! -L "$settings_file"; test -w "$settings_file"
        '';
      };
      wallpaperSetup = pkgs.writeShellApplication {
        name = "noctalia-wallpaper-cache-setup";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
        ];
        text = ''
              ${safeDirectoryLogic}
              cache_dir="$HOME/.cache/noctalia"; cache_file="$cache_dir/wallpapers.json"; tmp_file=""
              cleanup() { if [ -n "$tmp_file" ]; then rm -f "$tmp_file"; fi; }; trap cleanup EXIT
              ensure_directory "$HOME"; ensure_directory "$HOME/.cache"; ensure_directory "$cache_dir"; tmp_file=$(mktemp "$cache_dir/.wallpapers.json.XXXXXX")
          install -m 0644 "${wallpaperFile}" "$tmp_file"; jq -e . "$tmp_file" >/dev/null; mv -fT "$tmp_file" "$cache_file"; tmp_file=""
          test -f "$cache_file"; test ! -L "$cache_file"; test -w "$cache_file"
        '';
      };
      themeStubs = pkgs.writeShellApplication {
        name = "noctalia-theme-stubs";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          ensure_directory() { if [ -L "$1" ]; then printf 'Refusing symlink directory: %s\n' "$1" >&2; exit 1; fi; mkdir -p "$1"; if [ ! -d "$1" ] || [ -L "$1" ]; then printf 'Expected regular directory: %s\n' "$1" >&2; exit 1; fi; }
          ensure_file() { if [ -L "$1" ]; then printf 'Refusing symlink file: %s\n' "$1" >&2; exit 1; fi; if [ -e "$1" ] && [ ! -f "$1" ]; then printf 'Expected regular file: %s\n' "$1" >&2; exit 1; fi; }
          ensure_directory "$HOME/.config"; ensure_directory "$HOME/.config/niri"; ensure_directory "$HOME/.config/qt6ct"; ensure_directory "$HOME/.config/qt6ct/colors"
          niri_theme="$HOME/.config/niri/noctalia.kdl"; ensure_file "$niri_theme"; if [ ! -e "$niri_theme" ]; then printf '%s\n' '// populated by Noctalia' > "$niri_theme"; fi
          qt_theme="$HOME/.config/qt6ct/colors/noctalia.conf"; ensure_file "$qt_theme"; if [ ! -e "$qt_theme" ]; then : > "$qt_theme"; fi
        '';
      };
      service = name: description: setup: extra: {
        inherit description;
        before = [ "noctalia.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${setup}/bin/${name}";
        }
        // extra;
      };
    in
    lib.mkIf (lib.elem "noctalia" config.nixComputers.profileFeatures) {
      packages = [
        flake.packages.${system}.noctalia-shell
        pkgs.nwg-look
      ];
      systemd.services = {
        noctalia-settings-setup =
          service "noctalia-settings-setup" "Install Noctalia settings" settingsSetup {
            RemainAfterExit = true;
          }
          // {
            restartTriggers = [ settingsFile ];
          };
        noctalia-theme-stubs =
          service "noctalia-theme-stubs" "Create Noctalia theme stub files" themeStubs
            { };
        noctalia-wallpaper-cache =
          service "noctalia-wallpaper-cache-setup" "Install Noctalia wallpaper cache" wallpaperSetup {
            RemainAfterExit = true;
          }
          // {
            restartTriggers = [ wallpaperFile ];
          };
        noctalia = {
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
            ExecStart = "${flake.packages.${system}.noctalia-shell}/bin/noctalia-shell";
            Restart = "on-failure";
            RestartSec = 2;
          };
          restartTriggers = [ (pkgs.writeText "noctalia-settings-hjem-enabled" "1") ];
          wantedBy = [ "graphical-session.target" ];
        };
      };
      xdg.config.files =
        lib.genAttrs
          [
            "systemd/user/noctalia-settings-setup.service"
            "systemd/user/noctalia-theme-stubs.service"
            "systemd/user/noctalia-wallpaper-cache.service"
            "systemd/user/noctalia.service"
            "systemd/user/graphical-session.target.wants/noctalia.service"
          ]
          (_: {
            clobber = true;
          });
    };
}
