{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "linear-notify";
  version = "0.1.0";
  src = ./.;

  buildInputs = [ pkgs.python3 ];

  installPhase = ''
    runHook preInstall

    install -Dm755 linear-notify.py $out/bin/linear-notify
    substituteInPlace $out/bin/linear-notify \
      --replace-fail '@notifySend@' '${pkgs.libnotify}/bin/notify-send' \
      --replace-fail '@xdgOpen@' '${pkgs.xdg-utils}/bin/xdg-open'
    patchShebangs $out/bin/linear-notify

    runHook postInstall
  '';
}
