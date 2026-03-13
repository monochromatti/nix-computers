{ inputs, ... }:
let
  commonPackages =
    {
      pkgs,
      ...
    }:
    let
      latex = pkgs.texliveMedium.withPackages (ps: with ps; [ arara ]);
      daily-hours = inputs.daily-hours.packages.${pkgs.stdenv.hostPlatform.system}.default;
      upkgs = import inputs.nixpkgs-unstable {
        system = pkgs.stdenv.hostPlatform.system;
      };
    in
    {
      home.packages = [
        daily-hours

        # Nix
        pkgs.nixfmt-rfc-style
        pkgs.nixpkgs-fmt
        pkgs.nixd

        # Rust
        pkgs.rust-analyzer
        pkgs.cargo

        # Python
        upkgs.uv
        upkgs.ty
        upkgs.ruff

        # JavaScript
        upkgs.nodejs_24

        # Graphics
        pkgs.d2
        pkgs.silicon

        # Dev
        pkgs.gh
        pkgs.git
        pkgs.docker
        pkgs.azure-cli
        pkgs.qemu
        upkgs.devenv

        # Security
        pkgs.bitwarden-desktop

        # Shell
        pkgs.eza
        pkgs.ripgrep

        # Docs
        pkgs.pandoc
        pkgs.quarto
        latex
      ];
    };

  linuxPackages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Terminal
        ghostty
        xclip

        # UI programs
        spotify
        kdePackages.okular
        libreoffice
        keymapp

        # Text editors
        obsidian

        # Graphics
        inkscape
        gimp

        # Docker
        docker-compose

        # NATS
        natscli
        nsc

        # Other
        gpu-screen-recorder
      ];
    };
in
{
  flake.modules.homeManager.packages = commonPackages;

  flake.modules.nixos.packages = {
    home-manager.sharedModules = [ linuxPackages ];
  };
}
