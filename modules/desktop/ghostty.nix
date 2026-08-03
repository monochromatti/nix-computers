{ config, inputs, ... }:
let
  flake = config.flake;
  sharedSettings = {
    font-family = "JetBrains Mono";
    window-padding-x = 8;
    window-padding-y = 8;
    cursor-style = "block";
    background-opacity = flake.desktop.opacity;
    background-opacity-cells = true;
  };
  linuxSettings = sharedSettings // {
    font-size = flake.desktop.font.size;
  };

  mkWrapper =
    pkgs:
    inputs.wrappers.wrapperModules.ghostty.apply {
      inherit pkgs;
      settings = linuxSettings;
      configFile.content = inputs.nixpkgs.lib.generators.toKeyValue {
        listsAsDuplicateKeys = true;
      } linuxSettings;
      filesToPatch = inputs.nixpkgs.lib.mkAfter [ "share/applications/*.desktop" ];
    };
in
{
  flake.desktop.ghostty = {
    inherit sharedSettings linuxSettings;
    wrapper = mkWrapper;
  };

  perSystem =
    { pkgs, ... }:
    {
      packages = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
        ghostty = (mkWrapper pkgs).wrapper;
      };
    };
}
