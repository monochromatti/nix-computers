{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "cli-microsoft365";
  version = "11.11.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@pnp/cli-microsoft365/-/cli-microsoft365-11.11.0.tgz";
    hash = "sha256-RdtTd3szeKVXSqNqLRRMuHKsyoPFYJt4q1mBBR59LRc=";
  };

  npmDepsHash = "sha256-twHj75wONySFo0yCkBvLtvGaj++jWdceWsIeVWuT/UU=";
  npmDepsFetcherVersion = 2;
  postPatch = ''
    rm npm-shrinkwrap.json
    ${lib.getExe pkgs.jq} 'del(.devDependencies, .peerDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
    cp ${./package-lock.json} package-lock.json
  '';
  npmInstallFlags = [ "--omit=dev" ];
  dontNpmBuild = true;

  nativeBuildInputs = [ pkgs.jq ];

  meta = {
    description = "CLI for Microsoft 365 administration and development";
    homepage = "https://github.com/pnp/cli-microsoft365";
    license = lib.licenses.mit;
    mainProgram = "m365";
    platforms = lib.platforms.unix;
  };
}
