{ ... }:
{
  perSystem = { pkgs, lib, ... }: {
    pi.extensions = [
      (pkgs.stdenv.mkDerivation {
        pname = "pi-web-search";
        version = "1.6.0";

        src = pkgs.fetchFromGitHub {
          owner = "ttttmr";
          repo = "pi-web-search";
          rev = "8017f377178bbac28974d6da83fa9ea8b374f644";
          hash = "sha256-XVVw316rAkGZ1l4qg6VeJN8pQAGK7AVhdoCjOYvZC/k=";
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
