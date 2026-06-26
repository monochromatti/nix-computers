{ config, inputs, ... }:
let
  flake = config.flake;
  username = "monochromatti";
  users = flake.lib.users;
in
{
  flake.modules.homeManager.${username} =
    { config, lib, ... }:
    {
      imports = with flake.modules.homeManager; [
        packages
        ghostty
        zed
        linux
      ];

      gtk.gtk4.theme = lib.mkIf config.gtk.enable config.gtk.theme;

      programs = {
        home-manager.enable = true;
        ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."*".WarnWeakCrypto = "no";
        };
        zsh.dotDir = config.home.homeDirectory;
      };

      home = {
        inherit username;
        stateVersion = "24.05";
      };
    };

  flake.modules.nixos.${username} =
    { ... }:
    {
      imports = [
        inputs.hjem.nixosModules.default
        flake.modules.nixos.userdirs
      ];

      home-manager.sharedModules = [
        flake.modules.homeManager.${username}
      ];

      hjem.users.${username} = {
        user = username;
        directory = users.${username}.home.linux;
      };

      home-manager.users.${username}.home.homeDirectory = users.${username}.home.linux;
    };

  flake.modules.darwin.${username} =
    { ... }:
    {
      imports = [
        inputs.hjem.darwinModules.default
      ];

      home-manager.sharedModules = [
        flake.modules.homeManager.${username}
      ];

      users.users.${username} = {
        name = username;
        home = users.${username}.home.darwin;
      };

      system.primaryUser = username;

      hjem.users.${username} = {
        user = username;
        directory = users.${username}.home.darwin;
      };

      home-manager.users.${username} = { };
    };
}
