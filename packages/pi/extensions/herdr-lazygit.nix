{ pkgs, lib }:
pkgs.stdenv.mkDerivation {
  pname = "herdr-lazygit";
  version = "0.4.0";

  src = pkgs.fetchFromGitHub {
    owner = "Crokily";
    repo = "herdr-lazygit";
    rev = "e085baf5fb1a474f93d2f989d058ee82fceb21b2";
    hash = "sha256-G0Jmwhsw0aYx1lomdM4eXz5uDrbDh/WPeTA94wjzWvo=";
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
