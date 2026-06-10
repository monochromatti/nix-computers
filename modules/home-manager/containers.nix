{
  flake.modules.homeManager.containers =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        docker_29
        docker-compose
      ];
    };
}
