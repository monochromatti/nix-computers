{ inputs, ... }:
{
  flake.modules.homeManager.zed =
    { pkgs, ... }:
    let
      upkgs = import inputs.nixpkgs-unstable {
        system = pkgs.stdenv.hostPlatform.system;
        overlays = [ inputs.utgard.overlays.ty ];
      };
    in
    with pkgs.lib;
    {
      home.packages = with pkgs; [
        package-version-server
        just
      ];

      programs.zed-editor = {
        enable = true;
        package = upkgs.zed-editor;
        extensions = [
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
          file_types = {
            "Markdown" = [ "qmd" ];
            "JSON" = [
              "json"
              "avsc"
            ];
          };
          load_direnv = "shell_hook";
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
              binary.path = "package-version-server";
            };
            ty = {
              binary = {
                path = getExe upkgs.ty;
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
