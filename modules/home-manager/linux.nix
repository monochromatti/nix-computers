{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.homeManager.linux =
    {
      config,
      pkgs,
      lib,
      upkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      fontSize = flake.desktop.font.size;
      noctaliaShell = "${flake.packages.${system}.noctalia-shell}/bin/noctalia-shell";
      niri = "${pkgs.niri}/bin/niri";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      noctaliaWallpaper = toString ../../dotfiles/wallpapers/aishot-4712.jpg;
    in
    {
      xdg = {
        enable = true;
        configFile = lib.optionalAttrs pkgs.stdenv.isLinux {
          "noctalia/settings.json".text = builtins.toJSON flake.desktop.noctalia.settings;
          "vicinae/settings.json".text = ''
            {
              "theme": {
                "dark": {
                  "name": "nord",
                  "icon_theme": "Papirus-Dark"
                }
              },
              "launcher_window": {
                "layer_shell": {
                  "enabled": false
                }
              },
              "providers": {
                "power": {
                  "entrypoints": {
                    "lock": {
                      "preferences": {
                        "customProgram": "${noctaliaShell} ipc --any-display -n call sessionMenu lock",
                        "confirm": false
                      }
                    },
                    "suspend": {
                      "preferences": {
                        "customProgram": "${noctaliaShell} ipc --any-display -n call sessionMenu lockAndSuspend",
                        "confirm": true
                      }
                    },
                    "sleep": {
                      "preferences": {
                        "customProgram": "${noctaliaShell} ipc --any-display -n call sessionMenu lockAndSuspend",
                        "confirm": true
                      }
                    },
                    "hibernate": {
                      "preferences": {
                        "customProgram": "${systemctl} hibernate",
                        "confirm": true
                      }
                    },
                    "reboot": {
                      "preferences": {
                        "customProgram": "${systemctl} reboot",
                        "confirm": true
                      }
                    },
                    "soft-reboot": {
                      "preferences": {
                        "customProgram": "${systemctl} soft-reboot",
                        "confirm": true
                      }
                    },
                    "power-off": {
                      "preferences": {
                        "customProgram": "${systemctl} poweroff",
                        "confirm": true
                      }
                    },
                    "logout": {
                      "preferences": {
                        "customProgram": "${niri} msg action quit --skip-confirmation",
                        "confirm": true
                      }
                    }
                  }
                }
              }
            }
          '';

          "qt6ct/qt6ct.conf".text = ''
            [Appearance]
            color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
            custom_palette=true
            icon_theme=Papirus-Dark
            style=Fusion

            [Fonts]
            fixed="JetBrains Mono,${toString fontSize},-1,5,400,0,0,0,0,0"
            general="Inter,${toString fontSize},-1,5,400,0,0,0,0,0"
          '';
        };

      };

      gtk = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
        font = {
          name = "Inter";
          package = pkgs.inter;
          size = fontSize;
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
            ExecStart = "${flake.packages.${system}.noctalia-shell}/bin/noctalia-shell";
            Restart = "on-failure";
            RestartSec = 2;
          };

          Install.WantedBy = [ "graphical-session.target" ];
        };

        vicinae = {
          Unit = {
            Description = "Vicinae launcher daemon";
            Documentation = [ "https://docs.vicinae.com" ];
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
            Requires = [ "dbus.socket" ];
          };

          Service = {
            ExecStart = "${upkgs.vicinae}/bin/vicinae server --replace --config ${config.xdg.configHome}/vicinae/settings.json";
            ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
            Restart = "always";
            RestartSec = 60;
            KillMode = "process";
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
              "$HOME/.config/qt6ct/colors" \
              "$HOME/.cache/noctalia"

            if [ ! -e "$HOME/.config/niri/noctalia.kdl" ]; then
              cat > "$HOME/.config/niri/noctalia.kdl" <<'EOF'
            // populated by Noctalia
            EOF
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
          flake.packages.${system}.noctalia-shell
          pkgs.nwg-look
          pkgs.qt6Packages.qt6ct
          upkgs.vicinae
        ];
      };
    };
}
