{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "herdr-lazygit";
  version = "0.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "Crokily";
    repo = "herdr-lazygit";
    rev = "v0.3.0";
    hash = "sha256-eXeUZEEO21hkAUWZiozxIamsJtfi5Cmf212vUMCLue4=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/bin"
    cp -R ./. "$out/"
    substituteInPlace "$out/herdr-plugin.toml" \
      --replace-fail '[[build]]' '# [[build]]' \
      --replace-fail 'command = ["/bin/sh", "scripts/install-runtime.sh"]' '# command = ["/bin/sh", "scripts/install-runtime.sh"]'
    ln -s ${lib.getExe pkgs.lazygit} "$out/bin/lazygit"
    ln -s ${lib.getExe pkgs.fzf} "$out/bin/fzf"
  '';

  meta = {
    description = "Lazygit sidebar plugin for Herdr";
    homepage = "https://github.com/Crokily/herdr-lazygit";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
