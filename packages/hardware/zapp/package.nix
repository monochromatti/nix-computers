{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  installShellFiles,
  stdenv,
  apple-sdk ? null,
}:

rustPlatform.buildRustPackage rec {
  pname = "zapp";
  version = "1.0.0-unstable-2026-05-03";

  src = fetchFromGitHub {
    owner = "zsa";
    repo = "zapp";
    rev = "aaffabf80e9e5c003b53d92163787b6c47906788";
    hash = "sha256-OBYElUfLTm/TI4rB6oosSC7DT/39yUuav093IjTJzlU=";
  };

  cargoHash = "sha256-0jmYOfuAfmq8vJvWww6WHjt1J5nRbDDFNFi/vN5ANk8=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk
  ];

  # Workspace contains zapp-oryx, but root workspace builds zapp CLI + zapp-core only.
  cargoBuildFlags = [
    "-p"
    "zapp"
  ];
  cargoTestFlags = [
    "-p"
    "zapp"
  ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm0644 udev/50-zsa.rules $out/lib/udev/rules.d/50-zsa.rules
  '';

  meta = {
    description = "Command-line firmware flashing tool for ZSA keyboards";
    homepage = "https://github.com/zsa/zapp";
    license = lib.licenses.mit;
    mainProgram = "zapp";
    platforms = lib.platforms.unix;
  };
}
