{ ... }:
let
  mkDirenvPackage =
    pkgs:
    if pkgs.stdenv.isDarwin then
      pkgs.direnv.overrideAttrs (_: {
        checkPhase = ''
          runHook preCheck
          make test-go test-bash test-zsh
          runHook postCheck
        '';
      })
    else
      pkgs.direnv;

  direnvModule =
    { pkgs, ... }:
    {
      programs.direnv = {
        enable = true;
        package = mkDirenvPackage pkgs;
        nix-direnv.enable = true;
        silent = true;
      };
    };
in
{
  flake.modules.darwin."feature/shell/direnv" = direnvModule;
  flake.modules.nixos."feature/shell/direnv" = direnvModule;
}
