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
        noctalia-shell = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = upkgs.noctalia-shell;
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
