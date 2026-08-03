{
  config,
  inputs,
  ...
}:
let
  flake = config.flake;
  username = "monochromatti";
in
{
  flake.modules.homeManager."user/${username}-wsl" = {
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

  flake.modules.nixos."user/${username}-wsl" =
    {
      upkgs,
      inputs,
      ...
    }:
    {
      nixComputers.primaryUser = username;

      imports = [
        inputs.hjem.nixosModules.default
        flake.modules.nixos."feature/users/userdirs"
      ];

      home-manager.sharedModules = [
        flake.modules.homeManager."user/${username}-wsl"
      ];

      hjem.extraModules = [
        flake.modules.hjem."internal/hjem-profile-schema"
      ];
      hjem.specialArgs = {
        inherit inputs upkgs;
      };

      hjem.users.${username} = {
        user = username;
        directory = "/home/${username}";
        nixComputers.profile = "wsl";
      };

      home-manager.users.${username}.home.homeDirectory = "/home/${username}";
    };
}
