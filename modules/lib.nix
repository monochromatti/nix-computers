{
  config,
  inputs,
  lib,
  ...
}:
let
  flake = config.flake;
  mkPackageSets = system: {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    upkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    mpkgs = inputs.nixpkgs-master.legacyPackages.${system};
  };

  mkSpecialArgs =
    system:
    (builtins.removeAttrs (mkPackageSets system) [ "pkgs" ])
    // {
      inherit inputs;
      flake = config.flake;
      self = inputs.self;
      inherit (inputs)
        home-manager
        nixos-hardware
        sops-nix
        ;
    };
in
{
  config.flake.lib = {
    inherit mkPackageSets;

    users = {
      monochromatti = {
        description = "Mattias Matthiesen";
        home = {
          darwin = "/Users/monochromatti";
          linux = "/home/monochromatti";
        };
      };
    };

    mkNixos = system: name: {
      ${name} = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = mkSpecialArgs system;
        modules = [
          flake.modules.nixos."host/${name}"
          { nixpkgs.hostPlatform = system; }
        ];
      };
    };

    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = mkSpecialArgs system;
        modules = [
          flake.modules.darwin."host/${name}"
          { nixpkgs.hostPlatform = system; }
        ];
      };
    };
  };
}
