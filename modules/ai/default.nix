{ config, inputs, ... }:
let
  flake = config.flake;
  aiModule =
    {
      pkgs,
      lib,
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
    {
      packages."delta-duck-query" = pkgs.callPackage ../../packages/delta-duck-query/package.nix {
        uvloom = inputs.uvloom;
      };
      packages.ai = pkgs.buildEnv {
        name = "ai";
        paths = [
          config.packages.pi
          config.packages."delta-duck-query"
          pkgs.playwright-test
          config.packages.tautology-triage
        ];
      };
    };

  flake.modules.darwin."feature/ai" = aiModule;
  flake.modules.nixos."feature/ai" = aiModule;
}
