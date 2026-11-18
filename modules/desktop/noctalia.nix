{ config, inputs, ... }:
let
  desktopConfig = config.nixComputers.desktop;
  theme = config.nixComputers.theme;
  base = {
    neutral = {
      day = {
        hue = 86;
        chroma = 0.013;
      };
      night = {
        hue = 240;
        chroma = 0.005;
      };
    };
    error = {
      hue = 33;
      chroma = 0.100;
    };
    warm = {
      hue = 33;
      chroma = 0.050;
    };
    ochre = {
      hue = 75;
      chroma = 0.050;
    };
  };
  shades =
    neutral:
    builtins.mapAttrs (
      role: lightness:
      let
        b = base.${role} or neutral;
      in
      "oklch(${toString lightness} ${toString b.chroma} ${toString b.hue})"
    );
  paper = {
    day = shades base.neutral.day {
      ground = 0.907;
      card = 0.927;
      paper = 0.947;
      selection = 0.867;
      rule = 0.793;
      ink2 = 0.354;
      ink = 0.084;
      error = 0.456;
      warm = 0.840;
      ochre = 0.870;
    };
    night = shades base.neutral.night {
      ground = 0.228;
      card = 0.246;
      paper = 0.264;
      selection = 0.323;
      rule = 0.376;
      ink2 = 0.685;
      ink = 0.885;
      error = 0.700;
      warm = 0.330;
      ochre = 0.340;
    };
  };
  noctaliaPalette =
    c:
    {
      black,
      white,
      brightWhite,
    }:
    let
      ansi = {
        inherit black white;
        red = c.error;
        green = c.ink;
        yellow = c.ink2;
        blue = c.ink;
        magenta = c.ink2;
        cyan = c.ink2;
      };
    in
    {
      primary = c.ink;
      on_primary = c.paper;
      secondary = c.ink2;
      on_secondary = c.paper;
      tertiary = c.ink2;
      on_tertiary = c.paper;
      error = c.error;
      on_error = c.paper;
      surface = c.paper;
      on_surface = c.ink;
      surface_container = c.card;
      on_surface_variant = c.ink2;
      outline_variant = c.rule;
      shadow = c.ground;
      hover = c.selection;
      on_hover = c.ink;
      terminal = {
        foreground = c.ink;
        background = c.paper;
        cursor = c.ink;
        cursor_text = c.paper;
        selection_fg = c.paper;
        selection_bg = c.ink;
        normal = ansi;
        bright = ansi // {
          black = c.ink2;
          white = brightWhite;
        };
      };
    };
  paperPalette = {
    version = 2;
    light = noctaliaPalette paper.day {
      black = paper.day.ink;
      white = paper.day.rule;
      brightWhite = paper.day.selection;
    };
    dark = noctaliaPalette paper.night {
      black = paper.night.rule;
      white = paper.night.ink;
      brightWhite = paper.day.paper;
    };
  };
in
{
  config.nixComputers.desktop.noctalia.settings = {
    shell = {
      font_family = theme.font.sans;
      setup_wizard_enabled = false;
      corner_radius_scale = 0.5;
      launch_apps_as_systemd_services = true;
      panel = {
        transparency_mode = "solid";
        shadow = false;
      };
    };
    bar.default = {
      thickness = 34;
      background_opacity = 1.0;
      compositor_blur = false;
      radius = 0;
      margin_ends = 0;
      margin_edge = 0;
      padding = 16;
      widget_spacing = 16;
      shadow = false;
      capsule = false;
      start = [
        "workspaces"
        "active_window"
      ];
      center = [ "clock" ];
      end = [
        "work"
        "tray"
        "notifications"
        "network"
        "volume"
        "battery"
        "theme_mode"
        "control-center"
      ];
    };
    widget.clock.format = "{:%a %d %b   %H:%M}";
    widget.network = {
      show_glyph = false;
      custom_label = "wifi";
    };
    widget.volume = {
      show_glyph = false;
      show_label = true;
      custom_label = "vol";
    };
    widget.tray.hidden = [
      "vicinae"
      "Pareto Security"
      "Bitwarden_status_icon_1"
    ];
    notification.background_opacity = 1.0;
    osd.background_opacity = 1.0;
    dock.enabled = false;
    lockscreen = {
      enabled = true;
      lock_before_suspend = true;
      transition = [ ];
    };
    wallpaper = {
      enabled = true;
      fill_mode = "crop";
      transition_on_startup = false;
      automation.enabled = false;
    };
    theme = {
      mode = "light";
      source = "custom";
      custom_palette = theme.colorScheme;
      templates = {
        enable_builtin_templates = true;
        builtin_ids = [
          "ghostty"
          "gtk3"
          "gtk4"
          "qt"
          "kcolorscheme"
        ];
        user = {
          vicinae = {
            input_path = "${inputs.noctalia-templates}/vicinae/vicinae.toml";
            output_path = "$XDG_DATA_HOME/vicinae/themes/noctalia.toml";
            post_hook = "vicinae theme set noctalia";
          };
          niri = {
            input_path = "${./paper-niri.kdl}";
            output_path = "$XDG_CONFIG_HOME/niri/noctalia.kdl";
          };
          monstar = {
            input_path = "${inputs.noctalia}/assets/templates/ghostty/ghostty";
            output_path = "$XDG_CONFIG_HOME/monstar/themes/noctalia";
          };
        };
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
      wallpaperDir = "${toString config.xdg.data.directory}/noctalia-wallpapers";
      wallpapers =
        pkgs.runCommand "paper-wallpapers"
          {
            preferLocalBuild = true;
            nativeBuildInputs = [
              (pkgs.python3.withPackages (p: [
                p.numpy
                p.pillow
              ]))
            ];
          }
          ''
            mkdir $out
            python3 ${./paper-wallpaper.py} ${
              pkgs.writeText "paper-wallpaper-palette.json" (
                builtins.toJSON {
                  light = paper.day;
                  dark = paper.night;
                }
              )
            } $out
          '';
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
            barWidget.setGlyphColor(on and "primary" or "error")
          end)
        end

        function onClick()
          noctalia.runAsync("${dailyHours}/bin/daily-hours work toggle --source noctalia", function(result)
            if result.exitCode == 0 then update() end
          end)
        end
        EOF
      '';
      palette = pkgs.runCommand "paper-palette.json" { } ''
        ${pkgs.python3}/bin/python3 ${./oklch-to-hex.py} \
          < ${pkgs.writeText "paper-palette-oklch.json" (builtins.toJSON paperPalette)} > $out
      '';
      zedTemplate = pkgs.runCommand "noctalia-zed-paper.json" { } ''
        sed -E \
          -e 's/"terminal\.(background|foreground)": "\{\{colors\.[a-z_]+\./"terminal.\1": "{{colors.terminal_\1./' \
          -e 's/"terminal\.ansi\.bright_([a-z]+)": "\{\{colors\.[a-z_]+\./"terminal.ansi.bright_\1": "{{colors.terminal_bright_\1./' \
          -e 's/"terminal\.ansi\.(dim_)?([a-z]+)": "\{\{colors\.[a-z_]+\./"terminal.ansi.\1\2": "{{colors.terminal_normal_\2./' \
          -e 's/colors\.surface_dim\./colors.surface./g' \
          -e 's/colors\.(on_)?[a-z]+_fixed(_dim|_variant)?\./colors.secondary./g' \
          ${inputs.noctalia-templates}/zed/zed.json > $out
        if grep -qE 'fixed|surface_dim|inverse' $out; then
          echo "zed template still uses HSL-derived Noctalia colours" >&2
          exit 1
        fi
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
          theme.templates.user.zed = {
            input_path = "${zedTemplate}";
            output_path = "$XDG_CONFIG_HOME/zed/themes/noctalia.json";
          };
          wallpaper = {
            directory = wallpaperDir;
            default.path = "${wallpaperDir}/paper-light.jpg";
          };
          hooks.theme_mode_changed = "noctalia msg wallpaper-set ${wallpaperDir}/paper-\$NOCTALIA_THEME_MODE.jpg";
        };
      };
      xdg.data.files."noctalia-wallpapers".source = wallpapers;
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
          "noctalia/palettes/${theme.colorScheme}.json".source = palette;
          "gtk-4.0/gtk.css" = {
            text = ''
              @import url("noctalia.css");
            '';
            clobber = true;
          };
        };
    };
}
