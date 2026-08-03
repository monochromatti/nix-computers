{ config, inputs, ... }:
let
  flake = config.flake;
  username = "monochromatti";
  users = flake.lib.users;
in
{
  flake.modules.homeManager.${username} =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = with flake.modules.homeManager; [
        ghostty
        zed
        linux
      ];

      programs = {
        home-manager.enable = true;
        ssh = lib.mkIf pkgs.stdenv.isDarwin {
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
        flake.modules.homeManager.${username}
      ];

      hjem.users.${username} = {
        user = username;
        directory = users.${username}.home.linux;
        packages =
          flake.userPackageGroups.gtk pkgs
          ++ flake.userPackageGroups.apps pkgs
          ++ flake.userPackageGroups.zed pkgs
          ++ flake.userPackageGroups.desktop pkgs
          ++ flake.userPackageGroups.documents pkgs
          ++ flake.userPackageGroups.terminal pkgs
          ++ flake.userPackageGroups.containers pkgs
          ++ flake.userPackageGroups.cloud pkgs
          ++ flake.userPackageGroups.publishing pkgs
          ++ flake.userPackageGroups.diagrams pkgs
          ++ flake.userPackageGroups.virtualization pkgs
          ++ flake.userPackageGroups.security pkgs
          ++ flake.userPackageGroups.linux {
            inherit pkgs upkgs;
          }
          ++ flake.userPackageGroups.development {
            inherit
              pkgs
              upkgs
              inputs
              ;
          }
          ++ [ flake.packages.${system}.hunk ];
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
        flake.modules.homeManager.desktop
        flake.modules.homeManager.cloud
        flake.modules.homeManager.documents
        flake.modules.homeManager.terminal
        flake.modules.homeManager.containers
        flake.modules.homeManager.diagrams
        flake.modules.homeManager.virtualization
        flake.modules.homeManager.publishing
        flake.modules.homeManager.development
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
