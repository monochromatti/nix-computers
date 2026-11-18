{ inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
in
{
  options.nixComputers.desktop = lib.mkOption {
    type = lib.types.submodule {
      options = {
        niri.settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
        noctalia.settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
      };
    };
    default = { };
  };
}
