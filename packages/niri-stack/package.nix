{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "niri-stack";
  runtimeInputs = [ pkgs.python3 ];
  text = ''
    set -euo pipefail

    usage() {
      cat <<'EOF'
    Usage: niri-stack [INTERNAL_OUTPUT] [EXTERNAL_OUTPUT]

    Centers external output above internal/laptop output using current logical sizes.
    Defaults:
      INTERNAL_OUTPUT: first output whose name starts with eDP
      EXTERNAL_OUTPUT: widest non-internal output

    Example:
      niri-stack
      niri-stack eDP-1 DP-1
    EOF
    }

    if [[ "''${1:-}" == "-h" || "''${1:-}" == "--help" ]]; then
      usage
      exit 0
    fi

    NIRI_OUTPUTS_JSON="$(niri msg -j outputs)"
    export NIRI_OUTPUTS_JSON

    positions="$(${pkgs.python3}/bin/python3 - "''${1:-}" "''${2:-}" <<'PY'
    import json
    import os
    import sys

    requested_internal = sys.argv[1] or None
    requested_external = sys.argv[2] or None
    outputs = json.loads(os.environ["NIRI_OUTPUTS_JSON"])

    def die(message):
        print(f"niri-stack: {message}", file=sys.stderr)
        sys.exit(1)

    if len(outputs) < 2:
        die("need at least two outputs")

    if requested_internal:
        internal_name = requested_internal
        if internal_name not in outputs:
            die(f"internal output not found: {internal_name}")
    else:
        internal_name = next((name for name in outputs if name.startswith("eDP")), None)
        if internal_name is None:
            die("could not auto-detect internal output; pass INTERNAL_OUTPUT")

    candidates = {name: output for name, output in outputs.items() if name != internal_name}
    if requested_external:
        external_name = requested_external
        if external_name not in outputs:
            die(f"external output not found: {external_name}")
        if external_name == internal_name:
            die("internal and external output must differ")
    else:
        external_name = max(candidates, key=lambda name: candidates[name]["logical"]["width"])

    internal = outputs[internal_name]["logical"]
    external = outputs[external_name]["logical"]

    internal_width = int(internal["width"])
    external_width = int(external["width"])
    external_height = int(external["height"])

    # Keep all coordinates non-negative while centering narrower output under/over wider one.
    external_x = max(0, (internal_width - external_width) // 2)
    internal_x = max(0, (external_width - internal_width) // 2)

    print(external_name, external_x, 0)
    print(internal_name, internal_x, external_height)
    PY
    )"

    while read -r output x y; do
      echo "niri msg output $output position set $x $y"
      niri msg output "$output" position set "$x" "$y"
    done <<<"$positions"
  '';
}
