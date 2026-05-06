{ inputs, ... }:
let
  wallpaperDir = toString ../../dotfiles/wallpapers;
in
{
  perSystem =
    {
      pkgs,
      upkgs,
      ...
    }:
    {
      packages = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        noctalia-shell =
          let
            # Workaround for workspace pill duplication on monitor hotplug.
            # noctalia-qs 0.0.10 (in nixpkgs-unstable) has a bug in
            # ObjectModel::diffUpdate that corrupts the workspace model on
            # permutation events (e.g. niri migrating workspaces between
            # outputs). Fixed upstream in v0.0.11+ via noctalia-qs PR #35.
            # See noctalia-shell issue #2463; nixpkgs PR #505125 will retire
            # this override once merged into nixpkgs-unstable.
            noctaliaQsFixed = upkgs.noctalia-qs.overrideAttrs (_: rec {
              version = "0.0.12";
              src = pkgs.fetchFromGitHub {
                owner = "noctalia-dev";
                repo = "noctalia-qs";
                tag = "v${version}";
                hash = "sha256-79JP2QTdvp1jg7HGxAW+xzhzhLnlKUi8yGXq9nDCeH0=";
              };
              # 0001-fix-unneccessary-reloads.patch already upstream as
              # fce16b9d in 0.0.11, would fail to apply.
              patches = [ ];
            });
            noctaliaShellFixed = upkgs.noctalia-shell.override {
              noctalia-qs = noctaliaQsFixed;
            };
          in
          inputs.wrappers.lib.wrapPackage {
            inherit pkgs;
            package = noctaliaShellFixed;
          };
      };
    };

  flake.desktop.noctalia.settings = {
    # Keep in sync with Noctalia's current settings schema. Without this,
    # Noctalia reruns all migrations on every start against a read-only
    # Home Manager symlinked settings.json.
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
      fontDefault = "Inter";
      fontFixed = "JetBrains Mono";
      panelBackgroundOpacity = 0.92;
    };

    location.weatherEnabled = false;

    dock.enabled = false;

    wallpaper = {
      enabled = true;
      overviewEnabled = false;
      directory = wallpaperDir;
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
      predefinedScheme = "Nord";
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
}
