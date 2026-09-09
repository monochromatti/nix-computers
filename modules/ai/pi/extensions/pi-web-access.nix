{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-web-access";
  version = "0.28.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "811ef82a6dd04fe4abd73fa40b079aa39ee1870d";
    hash = "sha256-pRAya3k3gFSZ9dOqUq5aBf3UaNbpeD2Q0LB+c0J8mvE=";
  };

  npmDepsHash = "sha256-40wTpjxKcv5aZ+Jd6aaUtx4A+o3IcE+UvGRE5vAlB1Q=";
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
