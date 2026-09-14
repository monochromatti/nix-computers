{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-mcp-adapter";
  version = "2.32.1-unstable-2026-09-05";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-mcp-adapter";
    rev = "8243eba3421e301c88c047444f34ab7d5d57163e";
    hash = "sha256-Z+Nc7aQJFnZKYAe6yQN0CFwYuekNahAcFRg+dDBpRVU=";
  };

  npmDepsHash = "sha256-Q/DGtRE1l41QBnAelBBx7q17dNzjo7p/xCVK5OCiN4Y=";
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
