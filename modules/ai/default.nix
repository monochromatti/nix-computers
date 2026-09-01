{ inputs, ... }:
let
  aiModule =
    {
      pkgs,
      lib,
      flake,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      # Some NixOS targets, such as the Lima dev VM, do not build the AI package.
      aiPackage = lib.attrByPath [ "packages" system "ai" ] null flake;
    in
    {
      environment.systemPackages = lib.optionals (aiPackage != null) [ aiPackage ];
    };
in
{
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      # Declarative herdr config; `theme.name = "terminal"` makes herdr
      # inherit the host terminal (ghostty) palette instead of its default
      # catppuccin theme.
      herdrConfig = (pkgs.formats.toml { }).generate "herdr-config.toml" {
        onboarding = false;
        experimental.kitty_graphics = true;
        ui = {
          show_agent_labels_on_pane_borders = true;
          agent_panel_sort = "spaces";
        };
        theme.name = "terminal";
      };
      herdrPackage = inputs.llm-agents.packages.${system}.herdr;
    in
    {
      packages."delta-duck-query" = pkgs.callPackage ../../packages/delta-duck-query/package.nix {
        uvloom = inputs.uvloom;
      };
      packages.herdr = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = herdrPackage;
        env.HERDR_CONFIG_PATH = "${herdrConfig}";
        runtimeInputs = [ pkgs.jq ];
        preHook = ''
          plugin_root="${(import ./pi/extensions/pi-herdr-subagents.nix { inherit pkgs lib; })}/herdr-plugin"
          plugin_list="$(${lib.getExe herdrPackage} plugin list --json 2>/dev/null || true)"
          if ! printf '%s' "$plugin_list" | ${lib.getExe pkgs.jq} -e --arg plugin_root "$plugin_root" 'any(.result.plugins[]?; .plugin_root == $plugin_root)' >/dev/null; then
            ${lib.getExe herdrPackage} plugin link "$plugin_root" --enabled >/dev/null
          fi
        '';
      };

      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          config.packages.pi
          config.packages."delta-duck-query"
          config.packages.herdr
          pkgs.playwright-test
        ];
      };
    };

  flake.modules.darwin."feature/ai" = aiModule;
  flake.modules.nixos."feature/ai" = aiModule;
}
