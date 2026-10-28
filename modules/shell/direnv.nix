{ ... }:
let
  darwinDirenvPackage =
    pkgs:
    pkgs.direnv.overrideAttrs (_: {
      checkPhase = ''
        runHook preCheck
        make test-go test-bash test-zsh
        runHook postCheck
      '';
    });

  direnvModule = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
    };
  };
in
{
  flake.modules.darwin."feature/shell/direnv" =
    { pkgs, ... }:
    {
      imports = [ direnvModule ];
      programs.direnv.package = darwinDirenvPackage pkgs;
    };
  flake.modules.nixos."feature/shell/direnv" = direnvModule;
  flake.modules.hjem."feature/shell/direnv" = {
    xdg.config.files."direnv/direnv.toml".text = ''
      [whitelist]
      prefix = ["/home/monochromatti/"]
    '';
  };
}
