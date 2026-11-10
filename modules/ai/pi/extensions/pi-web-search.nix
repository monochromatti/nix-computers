{ ... }:
{
  perSystem = { pkgs, lib, ... }: {
    pi.extensions = [
      (pkgs.stdenv.mkDerivation {
        pname = "pi-web-search";
        version = "1.7.0";

        src = pkgs.fetchFromGitHub {
          owner = "ttttmr";
          repo = "pi-web-search";
          rev = "44bb62e22a6aab5a38451d863577cdb983cdf933";
          hash = "sha256-q5F7zahwAhYNBwTxa7PgzMtdhqJUamvjhmZM7qhIUec=";
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
      })
    ];
  };
}
