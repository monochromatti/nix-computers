{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "nautilus-copy-path";
  version = "unstable-2026-02-28";

  src = fetchFromGitHub {
    owner = "chr314";
    repo = "nautilus-copy-path";
    rev = "098d880d2ffbcb47651979aa53d05f9a05a071f8";
    hash = "sha256-DvBwqko45tcjfoBWpuas8pLGmkw2Gibwt5BtrN7gF0k=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm0644 nautilus-copy-path.py $out/share/nautilus-python/extensions/nautilus-copy-path.py
    install -Dm0644 nautilus_copy_path.py translation.py config.json \
      -t $out/share/nautilus-python/extensions/nautilus-copy-path
    install -d $out/share/nautilus-python/extensions/nautilus-copy-path/translations
    install -Dm0644 translations/*.json \
      -t $out/share/nautilus-python/extensions/nautilus-copy-path/translations
    runHook postInstall
  '';

  meta = {
    description = "Nautilus extension for copying paths, URIs, names, and file contents";
    homepage = "https://github.com/chr314/nautilus-copy-path";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
