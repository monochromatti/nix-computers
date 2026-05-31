{
  flake.modules.homeManager.documents =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        glow
        pandoc
      ];
    };
}
