{ ... }:
{
  flake.modules.hjem."feature/virtualization" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "virtualization" config.nixComputers.profileFeatures) {
      packages = [ pkgs.qemu ];
    };

  flake.modules.homeManager."feature/virtualization" = { pkgs, ... }: {
    home.packages = [ pkgs.qemu ];
  };
}
