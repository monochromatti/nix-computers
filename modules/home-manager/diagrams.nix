{
  flake.modules.homeManager.diagrams =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        d2
        silicon
      ];
    };
}
