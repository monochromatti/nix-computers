{ ... }:
{
  flake.modules.homeManager.ghostty =
    { pkgs, ... }:
    {
      xdg.enable = true;

      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isLinux then pkgs.ghostty else null;
        settings = {
          font-family = "JetBrains Mono";
          font-size = 11;
          window-padding-x = 8;
          window-padding-y = 8;
          cursor-style = "block";
        };
      };
    };
}
