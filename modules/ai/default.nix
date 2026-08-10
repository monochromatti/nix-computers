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
    { pkgs, config, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      # Declarative herdr config; `theme.name = "terminal"` makes herdr
      # inherit the host terminal (ghostty) palette instead of its default
      # catppuccin theme.
      herdrConfig = (pkgs.formats.toml { }).generate "herdr-config.toml" {
        onboarding = false;
        ui = {
          show_agent_labels_on_pane_borders = true;
          agent_panel_sort = "spaces";
        };
        theme.name = "terminal";
      };
    in
    {
      packages."delta-duck-query" = pkgs.callPackage ../../packages/delta-duck-query/package.nix {
        uvloom = inputs.uvloom;
      };
      packages.herdr = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = inputs.llm-agents.packages.${system}.herdr;
        env.HERDR_CONFIG_PATH = "${herdrConfig}";
      };

      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          config.packages.pi
          config.packages.pi-dev
          config.packages.omp
          config.packages."delta-duck-query"
          config.packages.herdr
          pkgs.playwright-test
        ];
      };
    };

  flake.modules.darwin."feature/ai" = aiModule;
  flake.modules.nixos."feature/ai" = aiModule;
}
