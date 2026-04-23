{ inputs, ... }:
{
  flake.modules.homeManager.linux =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      noctaliaWallpaper = toString ../../dotfiles/wallpapers/ign_unsplash27.png;
    in
    {
      xdg = {
        enable = true;
        configFile = lib.optionalAttrs pkgs.stdenv.isLinux {
          "ghostty/config".text = ''
            theme = noctalia
            font-family = JetBrains Mono
            font-size = 11
            window-padding-x = 8
            window-padding-y = 8
          '';

          "noctalia/settings.json".text = builtins.toJSON inputs.self.desktop.noctalia.settings;

          "qt6ct/qt6ct.conf".text = ''
            [Appearance]
            color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
            custom_palette=true
            icon_theme=Papirus-Dark
            style=Fusion

            [Fonts]
            fixed="JetBrains Mono,11,-1,5,400,0,0,0,0,0"
            general="Inter,11,-1,5,400,0,0,0,0,0"
          '';

          "walker/config.toml".text = ''
            force_keyboard_focus = true
            close_when_open = true
            click_to_close = true
            theme = "noctalia"

            [providers]
            default = [
              "providerlist",
              "desktopapplications",
              "runner",
              "calc",
              "files",
              "niri",
              "bluetooth",
              "wireplumber",
              "menus",
            ]
            empty = ["desktopapplications"]

            [placeholders]
            "default" = { input = "Search", list = "No Results" }
            "desktopapplications" = { input = "Launch App", list = "No Applications" }

            [keybinds]
            close = ["Escape"]
            next = ["Down"]
            previous = ["Up"]
          '';
        };
      };

      gtk = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        font = {
          name = "Inter";
          package = pkgs.inter;
          size = 11;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
      };

      home.pointerCursor = lib.mkIf pkgs.stdenv.isLinux {
        gtk.enable = true;
        x11.enable = true;
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 32;
      };

      fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.isLinux true;

      systemd.user.services = lib.mkIf pkgs.stdenv.isLinux {
        noctalia = {
          Unit = {
            Description = "Noctalia shell";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${inputs.self.packages.${system}.noctalia-shell}/bin/noctalia-shell";
            Restart = "on-failure";
            RestartSec = 2;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };

        elephant = {
          Unit = {
            Description = "Elephant backend for Walker";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = "${unstablePkgs.elephant}/bin/elephant";
            Restart = "on-failure";
            RestartSec = 2;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };

        walker = {
          Unit = {
            Description = "Walker launcher service";
            PartOf = [ "graphical-session.target" ];
            After = [
              "graphical-session.target"
              "elephant.service"
            ];
            Wants = [ "elephant.service" ];
          };

          Service = {
            Environment = [
              "PATH=${
                lib.makeBinPath [
                  unstablePkgs.walker
                  unstablePkgs.elephant
                ]
              }"
            ];
            ExecStart = "${unstablePkgs.walker}/bin/walker --gapplication-service";
            Restart = "on-failure";
            RestartSec = 2;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };
      };

      home = {
        sessionVariables = lib.optionalAttrs pkgs.stdenv.isLinux {
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };

        activation = lib.optionalAttrs pkgs.stdenv.isLinux {
          noctaliaThemeStubs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p \
              "$HOME/.config/niri" \
              "$HOME/.config/ghostty/themes" \
              "$HOME/.config/qt6ct/colors" \
              "$HOME/.cache/noctalia"

            if [ ! -e "$HOME/.config/niri/noctalia.kdl" ]; then
              cat > "$HOME/.config/niri/noctalia.kdl" <<'EOF'
            // populated by Noctalia
            EOF
            fi

            if [ ! -e "$HOME/.config/ghostty/themes/noctalia" ]; then
              : > "$HOME/.config/ghostty/themes/noctalia"
            fi

            if [ ! -e "$HOME/.config/qt6ct/colors/noctalia.conf" ]; then
              : > "$HOME/.config/qt6ct/colors/noctalia.conf"
            fi

            cat > "$HOME/.cache/noctalia/wallpapers.json" <<'EOF'
            {"wallpapers":{},"defaultWallpaper":"${noctaliaWallpaper}","usedRandomWallpapers":{}}
            EOF
          '';
        };

        packages = lib.optionals pkgs.stdenv.isLinux [
          pkgs.nwg-look
          pkgs.qt6Packages.qt6ct
          unstablePkgs.elephant
          unstablePkgs.walker
        ];
      };
    };
}
