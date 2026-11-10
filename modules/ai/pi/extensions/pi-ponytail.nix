{ ... }:
{
  perSystem = { pkgs, lib, ... }: {
    pi.extensions = [
      (pkgs.stdenv.mkDerivation {
        pname = "pi-ponytail";
        version = "5.3.3";

        src = pkgs.fetchFromGitHub {
          owner = "DietrichGebert";
          repo = "ponytail";
          rev = "7801d061243d7b753bad0e0b3c057cd250b11755";
          hash = "sha256-CY0EifTY0UVc6/FPGVJjEfYEf/8QLsINQmoYYKZYh98=";
        };

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          mkdir -p "$out"
          cp -R ./. "$out/"
          for f in "$out"/skills/ponytail-*/SKILL.md; do
            sed -i "0,/^---$/s//---\ndisable-model-invocation: true/" "$f"
          done
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
