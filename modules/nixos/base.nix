{ inputs, ... }:
{
  flake.modules.nixos.base =
    { pkgs, lib, ... }:
    with lib;
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
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
        ];

        shells = [ pkgs.zsh ];
      };

      fonts.packages = with pkgs; [
        font-awesome
        jetbrains-mono
        cantarell-fonts
        source-sans-pro
        nerd-fonts.droid-sans-mono
        nerd-fonts._0xproto
      ];
    };
}
