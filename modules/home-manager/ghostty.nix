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
      fontSize = inputs.self.desktop.font.size;

      commonSettings = {
        font-family = "JetBrains Mono";
        window-padding-x = 8;
        window-padding-y = 8;
        cursor-style = "block";
        background-opacity = opacity;
        background-opacity-cells = true;
      };

      linuxSettings = {
        font-size = fontSize;
      };

      darwinSettings = {
        background-blur = "macos-glass-regular";
        macos-titlebar-style = "transparent";
      };
    in
    {
      xdg.enable = true;

      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
        settings =
          commonSettings
          // lib.optionalAttrs pkgs.stdenv.isLinux linuxSettings
          // lib.optionalAttrs pkgs.stdenv.isDarwin darwinSettings;
      };
    };
}
