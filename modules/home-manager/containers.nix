{
  flake.modules.homeManager.containers =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        docker
        docker-compose
      ];
    };
}
