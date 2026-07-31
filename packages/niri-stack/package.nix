{ pkgs, ... }:
let
  niriStackPy = pkgs.writeText "niri-stack.py" ''
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


    def mode_width(mode):
        if "width" in mode:
            return int(mode["width"])
        if isinstance(mode.get("size"), dict) and "width" in mode["size"]:
            return int(mode["size"]["width"])
        return None


    def mode_height(mode):
        if "height" in mode:
            return int(mode["height"])
        if isinstance(mode.get("size"), dict) and "height" in mode["size"]:
            return int(mode["size"]["height"])
        return None


    def mode_refresh(mode):
        for key in ("refresh_rate", "refreshRate", "refresh"):
            if key in mode and mode[key] is not None:
                hz = float(mode[key])
                if hz > 1000:
                    hz /= 1000
                return hz
        return None


    def format_refresh(hz):
        if hz is None:
            return None
        text = f"{hz:.3f}".rstrip("0").rstrip(".")
        return text or "0"


    def pick_max_mode(output):
        modes = output.get("modes") or []
        scored = []
        for mode in modes:
            width = mode_width(mode)
            height = mode_height(mode)
            if width is None or height is None:
                continue
            refresh = mode_refresh(mode) or 0
            scored.append((width * height, width, height, refresh))

        if scored:
            _, width, height, refresh = max(scored)
            refresh_text = format_refresh(refresh)
            if refresh_text and refresh > 0:
                return f"{width}x{height}@{refresh_text}", width, height
            return f"{width}x{height}", width, height

        logical = output.get("logical") or {}
        width = int(logical.get("width", 0))
        height = int(logical.get("height", 0))
        if width > 0 and height > 0:
            return f"{width}x{height}", width, height

        return None, None, None


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
    external_mode, external_mode_width, external_mode_height = pick_max_mode(outputs[external_name])

    internal_width = int(internal["width"])
    external_width = int(external_mode_width or external["width"])
    external_height = int(external_mode_height or external["height"])

    # Keep all coordinates non-negative while centering narrower output under/over wider one.
    external_x = max(0, (internal_width - external_width) // 2)
    internal_x = max(0, (external_width - internal_width) // 2)

    if external_mode:
        print("MODE", external_name, external_mode)
    print("POS", external_name, external_x, 0)
    print("POS", internal_name, internal_x, external_height)
  '';
in
pkgs.writeShellApplication {
  name = "niri-stack";
  runtimeInputs = [ pkgs.python3 ];
  text = ''
    set -euo pipefail

    usage() {
      printf '%s\n' \
        'Usage: niri-stack [INTERNAL_OUTPUT] [EXTERNAL_OUTPUT]' \
        "" \
        'Sets external output to max resolution, then centers it above internal/laptop output.' \
        'Defaults:' \
        '  INTERNAL_OUTPUT: first output whose name starts with eDP' \
        '  EXTERNAL_OUTPUT: widest non-internal output' \
        "" \
        'Example:' \
        '  niri-stack' \
        '  niri-stack eDP-1 DP-1'
    }

    if [[ "''${1:-}" == "-h" || "''${1:-}" == "--help" ]]; then
      usage
      exit 0
    fi

    NIRI_OUTPUTS_JSON="$(niri msg -j outputs)"
    export NIRI_OUTPUTS_JSON

    commands="$(${pkgs.python3}/bin/python3 ${niriStackPy} "''${1:-}" "''${2:-}")"

    while read -r kind output a b; do
      if [[ "$kind" == "POS" ]]; then
        echo "niri msg output $output position set $a $b"
        niri msg output "$output" position set "$a" "$b"
      elif [[ "$kind" == "MODE" ]]; then
        echo "niri msg output $output mode $a"
        niri msg output "$output" mode "$a"
      fi
    done <<<"$commands"
  '';
}
