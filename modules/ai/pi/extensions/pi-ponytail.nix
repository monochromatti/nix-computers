{ ... }:
{
  perSystem = { pkgs, lib, ... }: {
    pi.extensions = [
      (pkgs.stdenv.mkDerivation {
        pname = "pi-ponytail";
        version = "4.13.0";

        src = pkgs.fetchFromGitHub {
          owner = "DietrichGebert";
          repo = "ponytail";
          rev = "08e952d7a8057a57ce561ff1330d093fd92eec67";
          hash = "sha256-sf8WLd7PFXGRM7+LGaXDT/exA0YU9Ld8U5uZFBEqM/k=";
        };

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          mkdir -p "$out"
          cp -R ./. "$out/"
        '';

        meta = {
          description = "Minimalism mode for Pi and other AI coding agents";
          homepage = "https://github.com/DietrichGebert/ponytail";
          license = lib.licenses.mit;
        };
      })
    ];
  };
}
