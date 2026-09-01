{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-pretty";
  version = "0.6.23";

  src = pkgs.fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-pretty";
    rev = "9cf3cfb2413d01b1a0c31ef132945e3e4cbd419e";
    hash = "sha256-Z6y4pHTFSW0jEnYXx6oazy72zTPugi5K5+rD5VsRWCs=";
  };

  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
  '';

  meta = {
    description = "Pretty terminal output for Pi";
    homepage = "https://github.com/heyhuynhgiabuu/pi-pretty";
    license = lib.licenses.mit;
  };
}
