{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      updater = pkgs.writeShellApplication {
        name = "update-pi-extensions";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          git
          gnutar
          gzip
          gnused
          jq
          nix
          nix-prefetch-github
          nodejs
          prefetch-npm-deps
          python3
        ];
        text = builtins.readFile ./update-extensions.sh;
      };
    in
    {
      apps.update-pi-extensions = {
        type = "app";
        program = lib.getExe updater;
      };
    };
}
