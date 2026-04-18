{ ... }:
let
  wallpaperDir = toString ../../dotfiles/wallpapers;
in
{
  flake.desktop.noctalia.settings = {
    general = {
      radiusRatio = 1.0;
      iRadiusRatio = 1.0;
    };

    bar = {
      showCapsule = false;
      backgroundOpacity = 0.9;
      frameRadius = 12;
      widgetSpacing = 6;
      widgets.left = [
        {
          id = "CustomButton";
          icon = "rocket";
          leftClickExec = "fuzzel";
          generalTooltipText = "Open launcher";
        }
        { id = "Clock"; }
        { id = "SystemMonitor"; }
        { id = "ActiveWindow"; }
        { id = "MediaMini"; }
      ];
    };

    ui = {
      fontDefault = "Inter";
      fontFixed = "JetBrains Mono";
      panelBackgroundOpacity = 0.92;
    };

    dock.enabled = false;

    wallpaper = {
      enabled = true;
      overviewEnabled = false;
      directory = wallpaperDir;
      setWallpaperOnAllMonitors = true;
      linkLightAndDarkWallpapers = true;
      fillMode = "crop";
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
          "fuzzel"
          "ghostty"
          "gtk"
          "qt"
          "kcolorscheme"
          "niri"
          "zed"
          "zenBrowser"
        ];
  };
}
