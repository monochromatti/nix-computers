{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-web-access";
  version = "0.31.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "610a52033f1e9705c0023ff9e0fac399319310a3";
    hash = "sha256-ykR2slh8MkxxbP660h0rvk2Y7SaKv+Cw/lJC21JqGW8=";
  };

  npmDepsHash = "sha256-NiBtIPIYbL+36L5SuBAm1yJk86WON4FLtPGz1A/qdsY=";
  npmDepsFetcherVersion = 2;
  postPatch = ''
    cp ${./locks/pi-web-access.json} package-lock.json
  '';
  dontNpmBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
  '';

  meta = {
    description = "Web search, URL fetching, GitHub repo cloning, PDF extraction, and video understanding for Pi";
    homepage = "https://github.com/nicobailon/pi-web-access";
    license = lib.licenses.mit;
  };
}
