{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.34.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "74c5233c63ad0096077df925fd6135c3bf6b8c6b";
    hash = "sha256-YpiJROIG0/U81wAoImjktbg/d5wGnc6o130IlOrTyEE=";
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
