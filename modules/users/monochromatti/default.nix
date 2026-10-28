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
  flake.modules.hjem."profile/wsl".imports = [
    flake.modules.hjem."feature/development"
    flake.modules.hjem."feature/shell/terminal"
    flake.modules.hjem."feature/shell/direnv"
    flake.modules.hjem."feature/documents"
    flake.modules.hjem."feature/ai"
  ];

  flake.modules.hjem."profile/workstation".imports = [
    flake.modules.hjem."profile/wsl"
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
    flake.modules.hjem."feature/desktop"
    flake.modules.hjem."feature/ghostty"
    flake.modules.hjem."feature/monstar"
    flake.modules.hjem."feature/zed"
    flake.modules.hjem."feature/applications"
  ];

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
      ];

      home-manager.sharedModules = [
        flake.modules.homeManager."user/${username}"
      ];
      hjem.specialArgs = {
        inherit inputs upkgs;
      };

      hjem.users.${username} = {
        user = username;
        directory = users.${username}.home.linux;
        imports = [ flake.modules.hjem."profile/workstation" ];
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
