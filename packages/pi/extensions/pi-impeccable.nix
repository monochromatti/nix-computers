{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-impeccable";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "jordi9";
    repo = "pi-impeccable";
    rev = "819a51b024490b6c081a489f951ecbc4f806e20e";
    hash = "sha256-FoyrhZX7RuVZEgWt22p5eZSp2KPH7/LMb0BXOWN+3Fs=";
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
