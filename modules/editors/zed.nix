{ config, ... }:
let
  theme = config.nixComputers.theme;
  extensionIds = [
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
  mkBaseSettings =
    lib:
    let
      inherit (lib) fixedWidthString toHexString;
      alpha = fixedWidthString 2 "0" (toHexString (builtins.floor (theme.opacity * 255.0)));
      transparent = color: "${color}${alpha}";
    in
    {
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
        Markdown = [ "qmd" ];
        JSON = [
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
      languages = {
        Python = {
          format_on_save = "on";
          code_actions_on_format."source.fixAll.ruff" = true;
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
        Markdown.soft_wrap = "editor_width";
        TOML.tab_size = 2;
      };
    };
  mkUserSettings =
    { lib, pkgs }:
    (mkBaseSettings lib)
    // {
      node = {
        path = lib.getExe pkgs.nodejs;
        npm_path = lib.getExe' pkgs.nodejs "npm";
      };
      lsp = {
        ruff = {
          binary = {
            path = lib.getExe pkgs.ruff;
            arguments = [ "server" ];
          };
          initialization_options.settings.configuration = "ruff.toml";
        };
        nixd.binary.path = lib.getExe pkgs.nixd;
        package-version-server.binary.path = lib.getExe pkgs.package-version-server;
        ty.binary = {
          path = lib.getExe pkgs.ty;
          arguments = [ "server" ];
        };
      };
    };
  settingsFile =
    { lib, pkgs }:
    (pkgs.formats.json { }).generate "zed-user-settings" (
      (mkUserSettings { inherit lib pkgs; })
      // {
        auto_install_extensions = lib.genAttrs extensionIds (_: true);
      }
    );
in
{
  flake.modules.hjem."feature/zed" =
    {
      config,
      lib,
      pkgs,
      upkgs,
      ...
    }:
    lib.mkIf (lib.elem "zed" config.nixComputers.profileFeatures) {
      packages = [
        pkgs.package-version-server
        pkgs.just
      ]
      ++ lib.optionals pkgs.stdenv.isLinux [ upkgs.zed-editor ];
      xdg.config.files."zed/settings.json" = {
        source = settingsFile { inherit lib pkgs; };
        clobber = true;
      };
    };

  flake.modules.homeManager."feature/zed" =
    {
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = lib.mkBefore (
        lib.optionals pkgs.stdenv.isDarwin [
          pkgs.package-version-server
          pkgs.just
        ]
      );
      programs.zed-editor = lib.mkIf pkgs.stdenv.isDarwin {
        enable = true;
        package = pkgs.zed-editor;
        mutableUserSettings = false;
        extensions = extensionIds;
        userSettings = mkUserSettings { inherit lib pkgs; };
      };
    };
}
