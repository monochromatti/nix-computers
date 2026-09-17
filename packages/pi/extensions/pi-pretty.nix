{ pkgs, lib }:
pkgs.buildNpmPackage {
  pname = "pi-pretty";
  version = "0.6.29";

  src = pkgs.fetchFromGitHub {
    owner = "heyhuynhgiabuu";
    repo = "pi-pretty";
    rev = "c0070d9c8585dd654dad83497fa4a7829b16c117";
    hash = "sha256-NSW78cGp/y8YX2pQ9hDATXUzf/dwVirxDdN4EavexEo=";
  };

  npmDepsHash = "sha256-tMoR5VaUzsWOsuEKFJ/qqQbRoXSCJNUGoQc5OaZkpDA=";
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
