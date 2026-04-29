{ inputs, ... }:
let
  mkPackageSets = system: {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    upkgs = import inputs.nixpkgs-unstable {
      inherit system;
      overlays = [ inputs.utgard.overlays.ty ];
    };
    mpkgs = inputs.nixpkgs-master.legacyPackages.${system};
  };

  mkSpecialArgs =
    system:
    (builtins.removeAttrs (mkPackageSets system) [ "pkgs" ])
    // {
      inherit inputs;
      inherit (inputs)
        home-manager
        nixos-hardware
        self
        sops-nix
        ;
    };
in
{
  flake.lib = {
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
          inputs.self.modules.nixos.${name}
          { nixpkgs.hostPlatform = system; }
        ];
      };
    };

    mkDarwin = system: name: {
      ${name} = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = mkSpecialArgs system;
        modules = [
          inputs.self.modules.darwin.${name}
          { nixpkgs.hostPlatform = system; }
        ];
      };
    };
  };
}
