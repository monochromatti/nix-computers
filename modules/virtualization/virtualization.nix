{ ... }:
{
  flake.modules.hjem."feature/virtualization" =
    {
      pkgs,
      ...
    }:
    {
      packages = [ pkgs.qemu ];
    };

  flake.modules.homeManager."feature/virtualization" = { pkgs, ... }: {
    home.packages = [ pkgs.qemu ];
  };
}
