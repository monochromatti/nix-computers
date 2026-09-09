{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-herdr-subagents";
  version = "0.2.0-unstable-2026-09-01";

  src = pkgs.fetchFromGitHub {
    owner = "modem-dev";
    repo = "pi-herdr-subagents";
    rev = "b6987324284b1fa22b2eb9f0effaf956ada27333";
    hash = "sha256-c8zNMN5624hvGckWZDtQ5pnfxrnYDuB477xdlbbsPzk=";
  };

  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
  '';

  meta = {
    description = "Interactive pi subagent orchestration in Herdr panes";
    homepage = "https://github.com/modem-dev/pi-herdr-subagents";
    license = lib.licenses.mit;
  };
}
