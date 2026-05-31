{ config, ... }:
let
  flake = config.flake;
  username = "monochromatti";
  users = flake.lib.users;
in
{
  flake.modules.homeManager.${username} = {
    imports = with flake.modules.homeManager; [
      packages
      ghostty
      zed
      linux
      userdirs
    ];

    programs.home-manager.enable = true;

    home = {
      inherit username;
      stateVersion = "24.05";
    };
  };

  flake.modules.nixos.${username} =
    { ... }:
    {
      home-manager.sharedModules = [
        flake.modules.homeManager.${username}
      ];

      home-manager.users.${username}.home.homeDirectory = users.${username}.home.linux;
    };

  flake.modules.darwin.${username} =
    { ... }:
    {
      home-manager.sharedModules = [
        flake.modules.homeManager.${username}
      ];

      users.users.${username} = {
        name = username;
        home = users.${username}.home.darwin;
      };

      system.primaryUser = username;

      home-manager.users.${username} = { };
    };
}
