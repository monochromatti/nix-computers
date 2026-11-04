{ ... }:
{
  flake.modules.hjem."feature/ai".files.".config/billion-context/billion-context.json" = {
    text = builtins.toJSON {
      compress = {
        maxContextLimit = "85%";
        nudgeGrowthTokens = 100000;
      };
    };
    clobber = true;
  };

  perSystem =
    { pkgs, lib, ... }:
    {
      pi.extensions = [
        (pkgs.buildNpmPackage rec {
          pname = "billion-context";
          version = "0.1.212";

          src = pkgs.fetchurl {
            url = "https://registry.npmjs.org/billion-context/-/billion-context-${version}.tgz";
            hash = "sha512-Bwjl4StlMNcE3JWe15iKLATwk5q8rgiNgR/isk5fCnOYfhtE8vsrtJPCqA5WGvsT2yJ9p/j3k4NUAkQER5qjjg==";
          };

          npmDepsHash = "sha256-n8fAxPmZoir7W98RGmuHrenGhtwtG/6eO9Vx9IWkJnA=";
          npmDepsFetcherVersion = 2;
          npmInstallFlags = [ "--ignore-scripts" ];
          dontNpmBuild = true;
          postPatch = ''
            ${lib.getExe pkgs.jq} 'del(.devDependencies, .scripts)' package.json > package.json.new
            mv package.json.new package.json
            cp ${./locks/billion-context.json} package-lock.json
          '';
          installPhase = ''
            mkdir -p "$out"
            cp -R ./. "$out/"
          '';

          meta = {
            description = "Context compression for coding agents";
            homepage = "https://github.com/ranxianglei/billion-context";
            license = lib.licenses.mit;
          };
        })
      ];
    };
}
