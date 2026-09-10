{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-ponytail";
  version = "4.9.0";

  src = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "356918eba965ee1eac64bd3a7f0dd02108350de5";
    hash = "sha256-LPNMyHsri3+eeDmphEAKL1JgoRE4dLIPfZ4XZ+xu5UY=";
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
}
