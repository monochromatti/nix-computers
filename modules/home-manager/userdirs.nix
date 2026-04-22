{ ... }:
{
  flake.modules.homeManager.userdirs =
    { pkgs, lib, ... }:
    {
      xdg.configFile = lib.optionalAttrs pkgs.stdenv.isLinux {
        "user-dirs.dirs".source = ../../dotfiles/user-dirs.dirs;
      };
    };
}
