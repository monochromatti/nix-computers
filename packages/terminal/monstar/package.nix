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
  version = "1.1.0-unstable-2026-08-25";

  src = fetchFromGitHub {
    owner = "rockorager";
    repo = "monstar";
    rev = "537b676801df50be3de6cc414688d008e9a4aefc";
    hash = "sha256-RTBGA1qiBk/u8K/gpuhu+UjWq/U4EI8v2T44bGo4y6s=";
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
