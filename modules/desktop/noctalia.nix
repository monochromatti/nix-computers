{ config, inputs, ... }:
let
  desktopConfig = config.nixComputers.desktop;
  theme = config.nixComputers.theme;
in
{
  config.nixComputers.desktop.noctalia.settings = {
    shell = {
      font_family = theme.font.sans;
      setup_wizard_enabled = false;
      corner_radius_scale = 1.0;
      launch_apps_as_systemd_services = true;
      panel.transparency_mode = "soft";
    };
    bar.default = {
      background_opacity = 0.9;
      radius = 12;
      widget_spacing = 10;
      capsule = false;
      start = [
        "vicinae"
        "clock"
        "sysmon"
        "active_window"
        "media"
      ];
      center = [ "workspaces" ];
      end = [
        "work"
        "tray"
        "notifications"
        "battery"
        "volume"
        "brightness"
        "control-center"
      ];
    };
    widget.vicinae = {
      type = "custom_button";
      glyph = "rocket";
      tooltip = "Open launcher";
      actions.left = "exec vicinae toggle";
    };
    widget.tray.hidden = [ "vicinae" ];
    dock.enabled = false;
    lockscreen = {
      enabled = true;
      lock_before_suspend = true;
    };
    wallpaper = {
      enabled = true;
      fill_mode = "crop";
      transition_on_startup = false;
      automation.enabled = false;
    };
    theme = {
      mode = "dark";
      source = "builtin";
      builtin = theme.colorScheme;
      templates = {
        enable_builtin_templates = true;
        builtin_ids = [
          "ghostty"
          "gtk3"
          "gtk4"
          "qt"
          "kcolorscheme"
          "niri"
        ];
      };
    };
  };

  config.flake.modules.hjem."feature/noctalia" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      wallpaperName = builtins.baseNameOf desktopConfig.noctalia.wallpaper;
      dataDir = toString config.xdg.data.directory;
      dailyHours = inputs.daily-hours.packages.${system}.default;
      plugin = pkgs.runCommand "noctalia-plugins" { } ''
        mkdir -p "$out/daily-hours"
        cat > "$out/daily-hours/plugin.toml" <<'EOF'
        id = "monochromatti/daily-hours"
        name = "Daily Hours"
        version = "1.0.0"
        plugin_api = 3
        author = "monochromatti"

        [[widget]]
        id = "work"
        entry = "widget.luau"
        EOF
        cat > "$out/daily-hours/widget.luau" <<'EOF'
        noctalia.setUpdateInterval(3000)

        function update()
          noctalia.runAsync("${dailyHours}/bin/daily-hours work status", function(result)
            local on = result.exitCode == 0 and result.stdout:match("^%s*(%S+)") == "on"
            barWidget.setText("")
            barWidget.setGlyph(on and "briefcase" or "briefcase-off")
            barWidget.setTooltip(on and "Work time tracking is on" or "Work time tracking is off")
            barWidget.setGlyphColor(on and "#5cc14c" or "#ff756e")
          end)
        end

        function onClick()
          noctalia.runAsync("${dailyHours}/bin/daily-hours work toggle --source noctalia", function(result)
            if result.exitCode == 0 then update() end
          end)
        end
        EOF
      '';
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
    in
    {
      imports = [ inputs.noctalia.hjemModules.default ];
      packages = [ pkgs.nwg-look ];
      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        settings = lib.recursiveUpdate desktopConfig.noctalia.settings {
          plugins = {
            enabled = [ "monochromatti/daily-hours" ];
            source = [
              {
                name = "daily-hours";
                kind = "path";
                location = toString plugin;
                enabled = true;
              }
            ];
          };
          widget.work.type = "monochromatti/daily-hours:work";
          wallpaper = {
            directory = "${dataDir}/noctalia-wallpapers";
            default.path = "${dataDir}/noctalia-default-wallpaper/${wallpaperName}";
          };
        };
      };
      xdg.data.files = {
        "noctalia-wallpapers".source = ../../dotfiles/wallpapers;
        "noctalia-default-wallpaper/${wallpaperName}".source = desktopConfig.noctalia.wallpaper;
      };
      systemd.services.noctalia-theme-stubs = {
        description = "Create Noctalia theme stub files";
        before = [ "noctalia.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${themeStubs}/bin/noctalia-theme-stubs";
        };
      };
      systemd.services.noctalia = {
        requires = [ "noctalia-theme-stubs.service" ];
        after = [ "noctalia-theme-stubs.service" ];
      };
      xdg.config.files =
        lib.genAttrs
          [
            "systemd/user/noctalia-theme-stubs.service"
            "systemd/user/noctalia.service"
            "systemd/user/graphical-session.target.wants/noctalia.service"
          ]
          (_: {
            clobber = true;
          })
        // {
          "gtk-4.0/gtk.css".text = lib.mkAfter ''
            @import url("noctalia.css");
          '';
        };
    };
}
