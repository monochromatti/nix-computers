{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-pretty";
  version = "0.6.27";

  src = pkgs.fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-pretty";
    rev = "6363850cd2c0dd64545628ffeed9ba00e021bc01";
    hash = "sha256-POKMlTPpFHcWjossfx70F0z7+/Wh3ElaE8EefXnf2p8=";
  };

  npmDepsHash = "sha256-bQcY5VokCHyox7aA36f64n9CeMumyXLuDkEm+aJTTos=";
  postPatch = ''
    cp ${./locks/pi-pretty.json} package-lock.json
    ${lib.getExe pkgs.jq} 'del(.devDependencies, .peerDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';
  dontNpmBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
  '';

  meta = {
    description = "Pretty terminal output for Pi";
    homepage = "https://github.com/heyhuynhgiabuu/pi-pretty";
    license = lib.licenses.mit;
  };
}
