{
  flake.modules.homeManager.security =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        bitwarden-desktop
      ];
    };
}
