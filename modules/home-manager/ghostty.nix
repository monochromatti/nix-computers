{ inputs, ... }:
{
  flake.modules.homeManager.ghostty =
    {
      pkgs,
      lib,
      ...
    }:
    let
      opacity = inputs.self.desktop.opacity;
    in
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
          background-opacity = opacity;
          background-opacity-cells = true;
        }
        // lib.optionalAttrs pkgs.stdenv.isLinux {
          font-size = 11;
        };
      };
    };
}
