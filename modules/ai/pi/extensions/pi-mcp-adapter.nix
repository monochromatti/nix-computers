{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.32.1-unstable-2026-09-01";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "10a45367e033a32026987a75d6f401e37340c86f";
    hash = "sha256-/NrC8cVEdhswKEQcuVugNSOCGJ3/c6k2Qg8o6hg0X14=";
  };

  npmDepsHash = "sha256-dOdYmNJI8oXHMFJTxIlmGsIhpNcSuXrrSkT/u3LmhhM=";
  npmDepsFetcherVersion = 2;
  postPatch = ''
    cp ${./locks/pi-mcp-adapter.json} package-lock.json
  '';
  dontNpmBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
  '';

  meta = {
    description = "MCP adapter extension for Pi coding agent";
    homepage = "https://github.com/nicobailon/pi-mcp-adapter";
    license = lib.licenses.mit;
  };
}
