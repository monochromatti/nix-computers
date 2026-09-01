{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-herdr-subagents";
  version = "0.2.0-unstable-2026-08-31";

  src = pkgs.fetchFromGitHub {
    owner = "modem-dev";
    repo = "pi-herdr-subagents";
    rev = "007ec2eec90d4c6d9177f0de6ac7b3bde6301642";
    hash = "sha256-YdCdAULbURq7+b7I1PrAjpYP2339OEwBgfPnobxnpKo=";
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
