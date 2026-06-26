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
    {
      packages."delta-duck-query" = pkgs.callPackage ../../packages/delta-duck-query/package.nix {
        uvloom = inputs.uvloom;
      };

      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          config.packages.pi
          config.packages.pi-dev
          config.packages.omp
          config.packages."delta-duck-query"
          pkgs.playwright-test
        ];
      };
    };

  flake.modules.darwin.ai = aiModule;
  flake.modules.nixos.ai = aiModule;
}
