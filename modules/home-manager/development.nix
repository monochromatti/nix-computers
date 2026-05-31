{ inputs, ... }:
{
  flake.modules.homeManager.development =
    {
      pkgs,
      upkgs,
      ...
    }:
    let
      daily-hours = inputs.daily-hours.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

        # Dev
        pkgs.gh
        pkgs.git
        upkgs.devenv

        # AI
        upkgs.rtk
      ];
    };
}
