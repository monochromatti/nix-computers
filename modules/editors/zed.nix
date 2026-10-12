{
  config,
  inputs,
  lib,
  ...
}:
let
  providers = inputs.agents.packages.x86_64-linux.pi.configuration.agents.modelProviders;
  models = inputs.agents.packages.x86_64-linux.pi.configuration.models.providers;
  mkFoundryModel =
    provider: name:
    let
      definitions = models.${provider}.models or [ ];
      matches = builtins.filter (model: model.id == name) definitions;
      model = if matches == [ ] then { } else builtins.head matches;
    in
    {
      inherit name;
      max_tokens = model.contextWindow or 128000;
      capabilities = {
        tools = true;
        images = builtins.elem "image" (model.input or [ ]);
        parallel_tool_calls = false;
        prompt_cache_key = false;
        chat_completions = provider != "azure";
      };
    }
    // lib.optionalAttrs (model ? maxTokens) {
      max_output_tokens = model.maxTokens;
    };
  mkZed =
    { pkgs, upkgs }:
    inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = upkgs.zed-editor;
      preHook = ''
        if aienv_exports="$(${
          lib.getExe inputs.agents.packages.${pkgs.stdenv.hostPlatform.system}.aienv
        } --azure)"; then
          eval "$aienv_exports"
          unset aienv_exports
          export FOUNDRY_API_KEY="$AZURE_API_KEY"
          export ANTHROPIC_API_KEY="$AZURE_API_KEY"
        else
          echo "Foundry authentication failed; run 'az login' and check keysopenai Key Vault permissions." >&2
        fi
      '';
    };
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
        default_model = {
          provider = "foundry";
          model = providers.openai.default.model;
        };
      };
      language_models = {
        anthropic.api_url = providers.anthropic.endpoint.root;
        openai_compatible.foundry = {
          api_url = providers.openai.endpoint.v1;
          available_models =
            map (mkFoundryModel "azure") providers.openai.models
            ++ map (mkFoundryModel "deepseek") providers.deepseek.models
            ++ map (mkFoundryModel "azure-xai") providers.xai.models;
        };
      };
      edit_predictions = {
        provider = "copilot";
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
  perSystem =
    { pkgs, upkgs, ... }:
    {
      packages.zed-editor = mkZed { inherit pkgs upkgs; };
    };

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
      ++ lib.optionals pkgs.stdenv.isLinux [
        (mkZed { inherit pkgs upkgs; })
      ];
      xdg.config.files."zed/settings.json" = {
        source = settingsFile { inherit lib pkgs; };
        clobber = true;
      };
    };

  flake.modules.homeManager."feature/zed" =
    {
      lib,
      pkgs,
      upkgs,
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
        package = mkZed { inherit pkgs upkgs; };
        mutableUserSettings = false;
        extensions = extensionIds;
        userSettings = mkUserSettings { inherit lib pkgs; };
      };
    };
}
