{ config, inputs, ... }:
let
  flake = config.flake;
in
{
  flake.modules.nixos.base =
    {
      pkgs,
      lib,
      upkgs,
      ...
    }:
    with lib;
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        flake.modules.nixos.ai
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        overwriteBackup = true;
        extraSpecialArgs = {
          inherit upkgs;
        };
      };

      i18n.defaultLocale = mkDefault "en_US.UTF-8";

      nix = {
        settings = {
          auto-optimise-store = true;
          trusted-users = [
            "root"
            "monochromatti"
          ];
        };
        gc.options = "--delete-older-than 14d";
      };

      users.defaultUserShell = pkgs.zsh;

      programs = {
        zsh.enable = true;

        ssh.extraConfig = ''
          WarnWeakCrypto no
        '';

        direnv = {
          enable = true;
          nix-direnv.enable = true;
          silent = true;
        };
      };

      environment = {
        systemPackages = with pkgs; [
          httpie
          tmux
          inetutils
          cachix
          lazygit
          p7zip
        ];

        shells = [ pkgs.zsh ];
      };

      fonts.packages = with pkgs; [
        font-awesome
        inter
        jetbrains-mono
        cantarell-fonts
        source-sans-pro
        nerd-fonts.droid-sans-mono
        nerd-fonts._0xproto
      ];
    };
}
