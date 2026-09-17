{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-web-access";
  version = "0.29.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "09cd27175d4a3088a43708041d935231187c5a97";
    hash = "sha256-fNB5UqtNP9BXuQKQp3R61rIDRBVhXu4ub++pvq7/pe8=";
  };

  npmDepsHash = "sha256-0ScX5nMu3h8/KCysaeNiXj/DK7E3abY8LINAaAARhCc=";
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
