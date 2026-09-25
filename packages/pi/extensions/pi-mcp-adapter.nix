{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.37.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "28049dee20cd0ee809cf5a78442cf35dfa36659c";
    hash = "sha256-fZ6sAJhNjSMz/KVsuuNtjkomkI5rQ0qlWMpvFVPinEc=";
  };

  npmDepsHash = "sha256-dPkMyrZ3UypIaRQZRKxugklWqVHBW39F646q4F1jtNc=";
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
