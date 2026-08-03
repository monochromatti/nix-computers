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
  flake.modules.homeManager."${username}-wsl" = {
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

  flake.modules.nixos."${username}-wsl" =
    {
      pkgs,
      upkgs,
      inputs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
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
        packages =
          flake.userPackageGroups.documents pkgs
          ++ flake.userPackageGroups.terminal pkgs
          ++ flake.userPackageGroups.development {
            inherit
              pkgs
              upkgs
              inputs
              ;
          }
          ++ [ flake.packages.${system}.hunk ];
      };

      home-manager.users.${username}.home.homeDirectory = "/home/${username}";
    };
}
