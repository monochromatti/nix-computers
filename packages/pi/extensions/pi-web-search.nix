{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "pi-web-search";
  version = "1.6.0";

  src = pkgs.fetchFromGitHub {
    owner = "ttttmr";
    repo = "pi-web-search";
    rev = "66e14d30be2fc4b56ef4a0f77efd55cd81f1b5c4";
    hash = "sha256-IFqctNrbVWG721Bisz0nzKzVgPiDxJc3GZO4J+PMwQo=";
  };

  nativeBuildInputs = [ pkgs.jq ];
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -R ./. "$out/"
    jq '.peerDependencies |= with_entries(.value = "*")' package.json > "$out/package.json"
  '';

  meta = {
    description = "Provider-native web search for Pi";
    homepage = "https://github.com/ttttmr/pi-web-search";
    license = lib.licenses.mit;
  };
}
