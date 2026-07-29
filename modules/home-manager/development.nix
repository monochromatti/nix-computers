{ config, inputs, ... }:
let
  flake = config.flake;
in
{
  flake.modules.homeManager.development =
    {
      pkgs,
      upkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      daily-hours = inputs.daily-hours.packages.${system}.default;
      fornybar-keyring = inputs.python-package-index.packages.${system}.fornybar-keyring;
    in
    {
      imports = [ flake.modules.homeManager.hunk ];

      home.packages = [
        daily-hours

        # Nix
        pkgs.nixfmt
        pkgs.nixpkgs-fmt
        pkgs.nixd

        # Rust
        pkgs.rust-analyzer
        pkgs.cargo

        # Python
        upkgs.uv
        pkgs.ty
        upkgs.ruff
        fornybar-keyring

        # JavaScript
        upkgs.nodejs_24

        # Dev
        pkgs.gh
        pkgs.git
        pkgs.worktrunk
        upkgs.devenv

        # AI
        upkgs.rtk
      ];
    };
}
