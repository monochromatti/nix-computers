{ inputs, ... }:
{
  perSystem =
    { upkgs, ... }:
    {
      packages.zapp = upkgs.callPackage ../../packages/hardware/zapp/package.nix { };
    };

  flake.modules.darwin.hardware =
    { pkgs, ... }:
    let
      zapp = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zapp;
    in
    {
      environment.systemPackages = [ zapp ];
    };

  flake.modules.nixos.hardware =
    { pkgs, ... }:
    let
      zapp = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.zapp;
    in
    {
      environment.systemPackages = [ zapp ];
      services.udev.packages = [ zapp ];
    };
}
