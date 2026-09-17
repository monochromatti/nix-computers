{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.34.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "33bdc38d8dd3802f2b51ba1fe37e30ed7ae6a29a";
    hash = "sha256-nmvDX4urLUmcP3/HUdiwRsk8TtGwIHKIG2MIg8aARj0=";
  };

  npmDepsHash = "sha256-ZxrUJXi/seXm4OhAqbVdJO77J/VhDSRtEFFS5KN8pZA=";
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
