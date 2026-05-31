{ config, inputs, ... }:
let
  flake = config.flake;
  username = "monochromatti";
in
{
  flake.modules.homeManager."${username}-wsl" = {
    imports = [
      flake.modules.homeManager.wsl
    ];

    programs = {
      git = {
        enable = true;
        settings.user = {
          name = "monochromatti";
          email = "mattias.matthiesen@eviny.no";
        };
      };

      home-manager.enable = true;
    };

    home = {
      inherit username;
      stateVersion = "25.11";
    };
  };

  flake.modules.nixos."${username}-wsl" = {
    imports = [
      inputs.hjem.nixosModules.default
      flake.modules.nixos.userdirs
    ];

    home-manager.sharedModules = [
      flake.modules.homeManager."${username}-wsl"
    ];

    hjem.users.${username} = {
      user = username;
      directory = "/home/${username}";
    };

    home-manager.users.${username}.home.homeDirectory = "/home/${username}";
  };
}
