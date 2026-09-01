{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-web-access";
  version = "0.27.0";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-web-access";
    rev = "711cc41313202e277a248b1cc45942b6dc8927f7";
    hash = "sha256-ngIYSP0DykKYYnxklyLiabEw4ldTfqng/AvuujinUoI=";
  };

  npmDepsHash = "sha256-Koi3pQ7Iv7ztlHqAGFHzerjqEv3IAgjobbLjLh/5M5Q=";
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
