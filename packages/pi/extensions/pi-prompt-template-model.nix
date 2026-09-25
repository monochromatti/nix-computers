{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-prompt-template-model";
  version = "0.12.3";

  src = pkgs.fetchFromGitHub {
    owner = "nicobailon";
    repo = "pi-prompt-template-model";
    rev = "6da205917e549cbe8e855c1d241c616ae1fb1627";
    hash = "sha256-F0GXAqoYdD4ciiDSyNRL2WYqU5w8FVWaJ81yyLwV+jQ=";
  };

  npmDepsHash = "sha256-UA6vYzYDdvJavL9P933lZAAhaqCq7DoJuM4ZCvTGUWA=";
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
