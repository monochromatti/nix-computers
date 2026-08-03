{ ... }:
{
  flake.modules.nixos."feature/users/userdirs" =
    { config, lib, ... }:
    lib.mkIf (config.nixComputers.primaryUser != null) {
      hjem.users.${config.nixComputers.primaryUser}.xdg.config.files."user-dirs.dirs".source =
        ../../dotfiles/user-dirs.dirs;
    };
}
