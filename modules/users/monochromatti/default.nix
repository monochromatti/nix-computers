{ inputs, ... }:
let
  username = "monochromatti";
  users = inputs.self.lib.users;
in
{
  flake.modules.homeManager.${username} =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      agentPackages = inputs.agents.packages.${pkgs.system};
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
      noctaliaWallpaper = toString ../../../dotfiles/wallpapers/ign_unsplash27.png;
      noctaliaColorschemes = pkgs.fetchFromGitHub {
        owner = "noctalia-dev";
        repo = "noctalia-colorschemes";
        rev = "d82d8994be9de097c713f02ec5426484e3666e4f";
        hash = "sha256-zF8fYne7VoEspKADo7atnSKRXVwOZ8qn8xbDhdDQCFA=";
      };
    in
    {
      imports = with inputs.self.modules.homeManager; [
        packages
        shell
        zed
        aliases
      ];

      xdg = {
        enable = true;
        configFile = lib.optionalAttrs pkgs.stdenv.isLinux {
          "ghostty/config".text = ''
            theme = noctalia
            font-family = JetBrains Mono
            font-size = 13
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
            default = ["desktopapplications", "runner"]
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
          size = 10;
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

      fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.isLinux true;

      home = {
        sessionVariables = lib.optionalAttrs pkgs.stdenv.isLinux {
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };

        activation.noctaliaThemeStubs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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

        inherit username;
        stateVersion = "24.05";
        packages = [
          agentPackages.codex
          agentPackages.opencode
          agentPackages.claude
          (agentPackages.pi.configuration.apply {
            settings.packages = [
              "npm:pi-subagents"
              "npm:pi-intercom"
              "npm:pi-web-access"
              "npm:pi-boomerang"
              "npm:pi-skill-palette"
              "npm:pi-mcp-adapter"
              "npm:pi-move-session"
              "npm:pi-prompt-template-model"
              "npm:pi-ghostty"
              "npm:pi-thinking-steps"
              "git:github.com/monochromatti/pi-extensions"
            ];
          }).wrapper
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          pkgs.nwg-look
          pkgs.qt6Packages.qt6ct
          unstablePkgs.walker
        ];
        shellAliases = {
          sync-yggdrasil = ''
            gh repo sync && gh repo sync -b dev-base --force && gh repo sync -b dev --force
          '';
        };
      };
    };

  flake.modules.nixos.${username} =
    { ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.${username}
      ];

      home-manager.users.${username} = {
        home = {
          homeDirectory = users.${username}.home.linux;
          shellAliases = {
            start-vidar-prod = ''
              az vm start --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
            '';
            stop-vidar-prod = ''
              az vm deallocate --subscription 584a2d66-5adc-45d5-b796-9d69d54154d6 --resource-group asgard --name vidar
            '';
            start-vidar-dev = ''
              az vm start --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
            '';
            stop-vidar-dev = ''
              az vm deallocate --subscription 5111c8c6-28f3-4b11-a07f-0aef3ed4721d --resource-group asgard --name vidar
            '';
          };
        };
        xdg.configFile."user-dirs.dirs".source = ../../../dotfiles/user-dirs.dirs;
      };
    };

  flake.modules.darwin.${username} =
    { ... }:
    {
      home-manager.sharedModules = [
        inputs.self.modules.homeManager.${username}
      ];

      users.users.${username} = {
        name = username;
        home = users.${username}.home.darwin;
      };

      system.primaryUser = username;

      home-manager.users.${username} = { };
    };
}
