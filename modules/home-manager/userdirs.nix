{ ... }:
{
  flake.modules.nixos.userdirs = {
    hjem.users.monochromatti.xdg.config.files."user-dirs.dirs".source = ../../dotfiles/user-dirs.dirs;
  };
}
