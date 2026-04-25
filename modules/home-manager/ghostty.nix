{ ... }:
{
  flake.modules.homeManager.ghostty =
    { pkgs, lib, ... }:
    {
      xdg.enable = true;

      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isLinux then pkgs.ghostty else null;
        settings = {
          font-family = "JetBrains Mono";
          window-padding-x = 8;
          window-padding-y = 8;
          cursor-style = "block";
        } // lib.optionalAttrs pkgs.stdenv.isLinux {
          font-size = 11;
        };
      };
    };
}
