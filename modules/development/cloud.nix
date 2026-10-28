{ ... }:
{
  flake.modules.hjem."feature/development/cloud" =
    {
      pkgs,
      ...
    }:
    {
      packages = [ pkgs.azure-cli ];
    };

  flake.modules.homeManager."feature/development/cloud" = { pkgs, ... }: {
    home.packages = [ pkgs.azure-cli ];
  };
}
