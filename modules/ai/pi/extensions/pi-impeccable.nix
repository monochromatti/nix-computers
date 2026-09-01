{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-impeccable";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "jordi9";
    repo = "pi-impeccable";
    rev = "d46a777d49145a118c8a2766239ea54bb8fc5e5d";
    hash = "sha256-OTTOeRyM7QOMrp/OYTtj5m1rh2YcZjezsVD5fKVppZw=";
  };

  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
  '';

  meta = {
    description = "Run Impeccable skills from Pi without blocking the agent";
    homepage = "https://github.com/jordi9/pi-impeccable";
    license = lib.licenses.asl20;
  };
}
