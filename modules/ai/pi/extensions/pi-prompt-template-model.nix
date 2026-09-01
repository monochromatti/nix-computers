{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-prompt-template-model";
  version = "0.12.2";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-prompt-template-model";
    rev = "accfa7817f78942d918e436405cb4f1a90afa23a";
    hash = "sha256-dYFJ3Vtm2q3TCqbk9YLuhDis5dWL2MNe65yA8YRHW8E=";
  };

  npmDepsHash = "sha256-34O1SoM+tIML4PyL+1NllWxO5F2DbCZB3WxPbW+DHW8=";
  npmDepsFetcherVersion = 2;
  postPatch = ''
    cp ${./locks/pi-prompt-template-model.json} package-lock.json
  '';
  dontNpmBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
  '';

  meta = {
    description = "Prompt template model selector extension for Pi coding agent";
    homepage = "https://github.com/nicobailon/pi-prompt-template-model";
    license = lib.licenses.mit;
  };
}
