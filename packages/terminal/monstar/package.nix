{
  lib,
  stdenv,
  fetchFromGitHub,
  zig,
  pkg-config,
  ncurses,
  wayland,
  wayland-scanner,
  wayland-protocols,
  fontconfig,
  freetype,
  harfbuzz,
  libxkbcommon,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "monstar";
  version = "1.1.0-unstable-2026-09-15";

  src = fetchFromGitHub {
    owner = "rockorager";
    repo = "monstar";
    rev = "6032b4f7ddc18da155e3cf4211c6643e4ecce534";
    hash = "sha256-HcUlhVK+6vUPutx07uYRPYeU+0gKJsziViCsQLLRAvY=";
  };

  nativeBuildInputs = [
    zig
    pkg-config
    ncurses
  ];

  buildInputs = [
    wayland
    wayland-scanner
    wayland-protocols
    fontconfig
    freetype
    harfbuzz
    libxkbcommon
  ];

  zigDeps = zig.fetchDeps {
    inherit (finalAttrs) src pname version;
    fetchAll = true;
    hash = "sha256-JpYY9P94+8rjl3J/DI9ja/4i21uHb+1yHxrYVtVDXLQ=";
  };

  postConfigure = ''
    ln -s ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    TERMINFO="$out/share/terminfo" ${ncurses}/bin/infocmp -x monstar >/dev/null
  '';

  meta = {
    description = "Linux-native Wayland terminal emulator built on libghostty";
    homepage = "https://github.com/rockorager/monstar";
    license = lib.licenses.mit;
    mainProgram = "monstar";
    platforms = lib.platforms.linux;
  };
})
