{ config, ... }:
let
  flake = config.flake;

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

  opacity = flake.desktop.opacity;

  mkBaseSettings =
    lib:
    let
      inherit (lib) fixedWidthString toHexString;
      alpha = fixedWidthString 2 "0" (toHexString (builtins.floor (opacity * 255.0)));
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
        nixd = {
          binary.path = lib.getExe pkgs.nixd;
        };
        package-version-server = {
          binary.path = lib.getExe pkgs.package-version-server;
        };
        ty = {
          binary = {
            path = lib.getExe pkgs.ty;
            arguments = [ "server" ];
          };
        };

      };
    };

  zedUserSettings =
    { lib, pkgs }:
    (mkUserSettings { inherit lib pkgs; })
    // {
      auto_install_extensions = lib.genAttrs extensionIds (_: true);
    };

  zedPackage =
    { pkgs, upkgs }:
    # Keep stable Zed package in Home Manager on Darwin; Linux package lives in Hjem.
    if pkgs.stdenv.hostPlatform.isDarwin then pkgs.zed-editor else null;
in
{
  flake.zedUserSettings = zedUserSettings;

  flake.userPackageGroups.zed = pkgs: [
    pkgs.package-version-server
    pkgs.just
  ];

  flake.userPackageGroups.zedEditor =
    { pkgs, upkgs }:
    pkgs.lib.optionals pkgs.stdenv.isLinux [ upkgs.zed-editor ];

  flake.modules.homeManager.zed =
    {
      lib,
      pkgs,
      upkgs,
      ...
    }:
    {
      home.packages = lib.optionals pkgs.stdenv.isDarwin (flake.userPackageGroups.zed pkgs);

      programs.zed-editor = lib.mkIf pkgs.stdenv.isDarwin {
        enable = true;
        package = zedPackage { inherit pkgs upkgs; };
        mutableUserSettings = false;
        extensions = extensionIds;
        userSettings = mkUserSettings { inherit lib pkgs; };
      };
    };
}
