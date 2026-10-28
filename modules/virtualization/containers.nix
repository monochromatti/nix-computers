{ ... }:
{
  flake.modules.hjem."feature/virtualization/containers" =
    {
      pkgs,
      ...
    }:
    {
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
