{ config, ... }:
let
  flake = config.flake;
  package = { pkgs }: flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-stack;
in
{
  flake.modules.hjem."feature/desktop" =
    {
      pkgs,
      ...
    }:
    {
      packages = [ (package { inherit pkgs; }) ];
    };

  flake.modules.homeManager."feature/desktop" = { pkgs, ... }: {
    home.packages = [ (package { inherit pkgs; }) ];
  };
}
