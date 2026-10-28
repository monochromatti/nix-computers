{ inputs, ... }:
let
  packages =
    { pkgs, upkgs }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      daily-hours = inputs.daily-hours.packages.${system}.default;
      fornybar-keyring = inputs.python-package-index.packages.${system}.fornybar-keyring;
    in
    [
      daily-hours
      pkgs.nixfmt
      pkgs.nixpkgs-fmt
      pkgs.nixd
      pkgs.rust-analyzer
      pkgs.cargo
      upkgs.uv
      pkgs.ty
      upkgs.ruff
      fornybar-keyring
      upkgs.nodejs_24
      pkgs.gh
      pkgs.git
      pkgs.worktrunk
      upkgs.devenv
      upkgs.rtk
    ];
in
{
  flake.modules.hjem."feature/development" =
    {
      pkgs,
      upkgs,
      ...
    }:
    {
      packages = packages { inherit pkgs upkgs; };
    };

  flake.modules.homeManager."feature/development" = { pkgs, upkgs, ... }: {
    home.packages = packages { inherit pkgs upkgs; };
  };
}
