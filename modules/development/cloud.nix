{ ... }:
{
  flake.modules.hjem."feature/development/cloud" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "cloud" config.nixComputers.profileFeatures) {
      packages = [ pkgs.azure-cli ];
    };

  flake.modules.homeManager."feature/development/cloud" = { pkgs, ... }: {
    home.packages = [ pkgs.azure-cli ];
  };
}
