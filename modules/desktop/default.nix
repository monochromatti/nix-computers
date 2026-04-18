{ inputs, ... }:
{
  options.flake.desktop = inputs.nixpkgs.lib.mkOption {
    type = inputs.nixpkgs.lib.types.attrs;
    default = { };
  };
}
