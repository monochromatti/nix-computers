{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        inherit pkgs;
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };
    };
}
