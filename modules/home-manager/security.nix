{
  flake.modules.homeManager.security =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.isLinux [
        pkgs.bitwarden-desktop
      ];
    };
}
