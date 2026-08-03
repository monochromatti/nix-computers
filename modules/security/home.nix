{ ... }:
{
  flake.modules.hjem."feature/security" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "security" config.nixComputers.profileFeatures) {
      packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.bitwarden-desktop ];
    };

  flake.modules.homeManager."feature/security" = { lib, pkgs, ... }: {
    home.packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.bitwarden-desktop ];
  };
}
