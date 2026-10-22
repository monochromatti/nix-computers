{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      pi.extensions = [
        (pkgs.buildNpmPackage {
          pname = "billion-context-pi";
          version = "0.1.83";

          src = pkgs.fetchFromGitHub {
            owner = "ranxianglei";
            repo = "billion-context-pi";
            rev = "1cb6340df262933c8e640a7f45e19a7b34fe1ed8";
            hash = "sha256-Q4mE3xxCypCnTW5fiE+I73ZrpXTPlxzougUUs9E/pHI=";
          };

          npmDepsHash = "sha256-T1plL4GFcOZ1PEqo9wdfJS6MsgUYzOruQ00Rdn4cEt0=";
          npmDepsFetcherVersion = 2;
          postPatch = ''
            cp ${./locks/billion-context-pi.json} package-lock.json
          '';
          installPhase = ''
            mkdir -p "$out"
            cp -R ./. "$out/"
          '';

          meta = {
            description = "Model-driven context management for the Pi coding agent";
            homepage = "https://github.com/ranxianglei/billion-context-pi";
            license = lib.licenses.mit;
          };
        })
      ];
    };
}
