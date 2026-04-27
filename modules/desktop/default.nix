{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  options.flake.desktop = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf lib.types.anything;
      options.opacity = lib.mkOption {
        type = lib.types.float;
      };
    };
    default = { };
  };
}
