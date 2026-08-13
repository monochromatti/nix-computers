{
  config,
  inputs,
  lib,
  ...
}:
let
  flake = config.flake;
  username = "monochromatti";
  users = flake.lib.users;
in
{
  # Hjem extraModules are global, so import feature modules once and gate
  # each feature through typed profile membership per user.
  flake.modules.hjem."internal/hjem-profile-schema" =
    { config, lib, ... }:
    {
      imports = [
        flake.modules.hjem."feature/development/hunk"
        flake.modules.hjem."feature/development"
        flake.modules.hjem."feature/gtk"
        flake.modules.hjem."feature/qt"
        flake.modules.hjem."feature/noctalia"
        flake.modules.hjem."feature/vicinae"
        flake.modules.hjem."feature/overskride"
        flake.modules.hjem."feature/security"
        flake.modules.hjem."feature/virtualization"
        flake.modules.hjem."feature/documents/diagrams"
        flake.modules.hjem."feature/documents/publishing"
        flake.modules.hjem."feature/development/cloud"
        flake.modules.hjem."feature/virtualization/containers"
        flake.modules.hjem."feature/shell/terminal"
        flake.modules.hjem."feature/documents"
        flake.modules.hjem."feature/desktop"
        flake.modules.hjem."feature/ghostty"
        flake.modules.hjem."feature/zed"
        flake.modules.hjem."feature/applications"
        flake.modules.hjem."feature/ai"
      ];
      config.nixComputers.profileFeatures =
        if config.nixComputers.profile == "workstation" then
          [
            "development/hunk"
            "development"
            "gtk"
            "qt"
            "noctalia"
            "vicinae"
            "overskride"
            "security"
            "virtualization"
            "diagrams"
            "publishing"
            "cloud"
            "containers"
            "terminal"
            "documents"
            "desktop"
            "ghostty"
            "zed"
            "apps"
            "ai"
          ]
        else if config.nixComputers.profile == "wsl" then
          [
            "development/hunk"
            "development"
            "terminal"
            "documents"
            "ai"
          ]
        else
          [ ];
      options.nixComputers.profile = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "workstation"
            "wsl"
          ]
        );
        default = null;
        description = "Personal Hjem package profile selected for this user.";
      };

      options.nixComputers.profileFeatures = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "development/hunk"
            "development"
            "gtk"
            "qt"
            "noctalia"
            "vicinae"
            "overskride"
            "security"
            "virtualization"
            "diagrams"
            "publishing"
            "cloud"
            "containers"
            "terminal"
            "documents"
            "desktop"
            "ghostty"
            "zed"
            "apps"
            "ai"
          ]
        );
        default = [ ];
        internal = true;
        description = "Feature membership supplied by selected profile.";
      };

    };

  flake.modules.homeManager."profile/darwin" = {
    imports = [
      flake.modules.homeManager."feature/desktop"
      flake.modules.homeManager."feature/development/cloud"
      flake.modules.homeManager."feature/documents"
      flake.modules.homeManager."feature/shell/terminal"
      flake.modules.homeManager."feature/virtualization/containers"
      flake.modules.homeManager."feature/documents/diagrams"
      flake.modules.homeManager."feature/virtualization"
      flake.modules.homeManager."feature/documents/publishing"
      flake.modules.homeManager."feature/development"

      flake.modules.homeManager."feature/zed"
    ];
  };

  flake.modules.homeManager."user/${username}" =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [ flake.modules.homeManager."feature/ghostty" ];

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
      xdg.enable = true;
    };

  flake.modules.nixos."user/${username}" =
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
        flake.modules.homeManager."user/${username}"
      ];

      hjem.extraModules = [
        flake.modules.hjem."internal/hjem-profile-schema"
      ];
      hjem.specialArgs = {
        inherit inputs upkgs;
      };

      hjem.users.${username} = {
        user = username;
        directory = users.${username}.home.linux;
        nixComputers.profile = "workstation";
      };

      home-manager.users.${username}.home.homeDirectory = users.${username}.home.linux;
    };

  flake.modules.darwin."user/${username}" = {
    imports = [
      inputs.hjem.darwinModules.default
    ];

    home-manager.sharedModules = [
      flake.modules.homeManager."user/${username}"
      flake.modules.homeManager."profile/darwin"
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
