{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (
    ps: with ps; [
      azure-identity
      azure-keyvault-secrets
      duckdb
    ]
  );
in
pkgs.writeShellApplication {
  name = "delta-duck-query";
  runtimeInputs = [ python ];
  text = ''
    set -euo pipefail
    exec ${python}/bin/python ${./delta-duck-query.py} "$@"
  '';

  meta = {
    description = "Small CLI for querying Delta Lake with DuckDB";
    mainProgram = "delta-duck-query";
    platforms = pkgs.lib.platforms.unix;
  };
}
