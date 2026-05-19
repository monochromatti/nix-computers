{ inputs, ... }:
let
  username = "monochromatti";
in
{
  flake.modules.homeManager."${username}-wsl" = {
    imports = [
      inputs.self.modules.homeManager.wsl
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
    home-manager.sharedModules = [
      inputs.self.modules.homeManager."${username}-wsl"
    ];

    home-manager.users.${username}.home.homeDirectory = "/home/${username}";
  };
}
