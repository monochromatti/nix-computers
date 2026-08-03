{ ... }:
{
  flake.modules.hjem."feature/virtualization/containers" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (lib.elem "containers" config.nixComputers.profileFeatures) {
      packages = [
        pkgs.docker_29
        pkgs.docker-compose
      ];
    };

  flake.modules.homeManager."feature/virtualization/containers" = { pkgs, ... }: {
    home.packages = [
      pkgs.docker_29
      pkgs.docker-compose
    ];
  };
}
