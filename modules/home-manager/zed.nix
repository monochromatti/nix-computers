{ config, ... }:
let
  flake = config.flake;
in
{
  flake.userPackageGroups.zed = pkgs: [
    pkgs.package-version-server
    pkgs.just
  ];

  flake.modules.homeManager.zed =
    {
      lib,
      pkgs,
      upkgs,
      ...
    }:
    let
      opacity = flake.desktop.opacity;
      inherit (pkgs.lib)
        getExe
        getExe'
        fixedWidthString
        toHexString
        ;
      alpha = fixedWidthString 2 "0" (toHexString (builtins.floor (opacity * 255.0)));
      transparent = color: "${color}${alpha}";
    in
    {
      home.packages = lib.optionals pkgs.stdenv.isDarwin (flake.userPackageGroups.zed pkgs);

      programs.zed-editor = {
        enable = true;
        # Unstable Zed builds livekit-libwebrtc locally on Darwin; use cached stable package there.
        package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.zed-editor else upkgs.zed-editor;
        mutableUserSettings = false;
        extensions = [
          "nord"
          "nix"
          "toml"
          "mermaid"
          "basher"
          "log"
          "html"
          "sql"
          "just"
          "rainbow-csv"
          "terraform"
          "svelte"
        ];
        userSettings = {
          theme = {
            mode = "system";
            light = "Nord Light";
            dark = "Nord Dark";
          };
          theme_overrides = {
            "Nord Dark" = {
              "background.appearance" = "transparent";
              background = transparent "#2e3440";
              "title_bar.background" = transparent "#2e3440";
              "title_bar.inactive_background" = transparent "#252a34";
              "status_bar.background" = transparent "#2e3440";
            };
            "Nord Light" = {
              "background.appearance" = "transparent";
              background = transparent "#eceff4";
              "title_bar.background" = transparent "#eceff4";
              "title_bar.inactive_background" = transparent "#dfe4ed";
              "status_bar.background" = transparent "#eceff4";
            };
          };
          file_types = {
            "Markdown" = [ "qmd" ];
            "JSON" = [
              "json"
              "avsc"
            ];
          };
          load_direnv = "shell_hook";
          project_panel.dock = "left";
          agent = {
            dock = "right";
            sidebar_side = "right";
          };
          edit_predictions = {
            provider = "zed";
            mode = "subtle";
          };
          vim_mode = true;
          node = {
            path = getExe pkgs.nodejs;
            npm_path = getExe' pkgs.nodejs "npm";
          };
          lsp = {
            ruff = {
              binary = {
                path = getExe pkgs.ruff;
                arguments = [ "server" ];
              };
              initialization_options.settings.configuration = "ruff.toml";
            };
            nixd = {
              binary.path = getExe pkgs.nixd;
            };
            package-version-server = {
              binary.path = getExe pkgs.package-version-server;
            };
            ty = {
              binary = {
                path = getExe pkgs.ty;
                arguments = [ "server" ];
              };
            };
          };
          languages = {
            Python = {
              format_on_save = "on";
              code_actions_on_format = {
                "source.fixAll.ruff" = true;
              };
              language_servers = [
                "ruff"
                "ty"
                "!basedpyright"
              ];
            };
            Nix = {
              formatter.external.command = "nixfmt";
              language_servers = [
                "nixd"
                "!nil"
              ];
            };
            Markdown = {
              soft_wrap = "editor_width";
            };
            TOML = {
              tab_size = 2;
            };
          };
        };
      };
    };
}
