{ ... }:
{
  flake.modules.hjem."feature/security" =
    {
      lib,
      pkgs,
      ...
    }:
    {
      packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.bitwarden-desktop ];
    };

  flake.modules.homeManager."feature/security" = { lib, pkgs, ... }: {
    home.packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.bitwarden-desktop ];
  };
}
