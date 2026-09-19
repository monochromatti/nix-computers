{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-web-access";
  version = "0.29.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "192ac1875e3b8f88c78953dbc314949ec9fcaa27";
    hash = "sha256-5YMwE44pyMmCapGt9kFLxT61Qg3OCzuJCIATRhMBv6M=";
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
