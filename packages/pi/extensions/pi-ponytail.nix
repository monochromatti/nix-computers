{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-ponytail";
  version = "4.10.0";

  src = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "1d95ff7d39de12d87014ea40d4e22201bddc501b";
    hash = "sha256-PES5XrSYx0VBXWVHEDRykGy0SAmJfV/luzy8Gfg0aAQ=";
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
