{ config, ... }:
let
  flake = config.flake;
in
{
  flake.modules.homeManager.ghostty =
    {
      pkgs,
      lib,
      ...
    }:
    {
      xdg.enable = true;

      programs.ghostty = {
        enable = lib.mkIf pkgs.stdenv.isDarwin true;
        package = lib.mkIf pkgs.stdenv.isDarwin pkgs.ghostty-bin;
        settings = lib.mkIf pkgs.stdenv.isDarwin (
          flake.desktop.ghostty.sharedSettings
          // {
            background-blur = "macos-glass-regular";
            macos-titlebar-style = "transparent";
          }
        );
      };

      programs.bash.initExtra = lib.mkIf pkgs.stdenv.isLinux (
        lib.mkOrder 101 ''
          if [[ -n "''${GHOSTTY_RESOURCES_DIR}" ]]; then builtin source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"; fi
        ''
      );

      programs.fish.interactiveShellInit = lib.mkIf pkgs.stdenv.isLinux ''
        if set -q GHOSTTY_RESOURCES_DIR; source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"; end
      '';

      programs.zsh.initContent = lib.mkIf pkgs.stdenv.isLinux ''
        if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration; fi
      '';
    };
}
