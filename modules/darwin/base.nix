{ inputs, ... }:
{
  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      imports = [
        inputs.home-manager.darwinModules.home-manager
        inputs.sops-nix.darwinModules.sops
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };

      ids.gids.nixbld = 30000;

      nixpkgs.config.allowUnfree = true;

      environment.systemPackages = with pkgs; [
        mas
        colima
      ];

      nix = {
        enable = true;
        package = pkgs.nix;
        gc.automatic = true;
        optimise.automatic = true;
        settings = {
          trusted-users = [
            "root"
            "monochromatti"
          ];
          auto-optimise-store = false;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };

      security.pam.services.sudo_local.touchIdAuth = true;

      fonts.packages = with pkgs; [
        dejavu_fonts
        jetbrains-mono
        noto-fonts
        nerd-fonts.droid-sans-mono
      ];
    };
}
