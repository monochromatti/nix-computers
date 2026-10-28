{
  flake.modules.hjem."feature/security" =
    { pkgs, ... }:
    {
      packages = [ pkgs.bitwarden-desktop ];
    };
}
