{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-ponytail";
  version = "4.10.0";

  src = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "e3ba2aa6f1e6f0bc4d69eb09c9f0d0a93af56156";
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
