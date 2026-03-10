{
  lib,
  writeShellApplication,
  coreutils,
  nodejs,
  llmAgentsPi,
  aienv,
}:
writeShellApplication {
  name = "pi";
  runtimeInputs = [
    coreutils
    nodejs
  ];
  text = ''
    eval "$(${lib.getExe aienv} --azure)"
    : "''${AZURE_API_KEY:?aienv did not set AZURE_API_KEY}"
    : "''${AZURE_RESOURCE_NAME:?aienv did not set AZURE_RESOURCE_NAME}"

    export AZURE_OPENAI_API_KEY="$AZURE_API_KEY"
    export AZURE_OPENAI_RESOURCE_NAME="$AZURE_RESOURCE_NAME"

    npm_prefix="$HOME/.local/share/pi/npm"
    npm_cache="$HOME/.cache/pi/npm"
    npm_userconfig="$HOME/.config/pi/npm/npmrc"

    mkdir -p "$npm_prefix" "$npm_cache" "$(dirname "$npm_userconfig")"

    printf '%s\n' \
      "prefix=$npm_prefix" \
      "cache=$npm_cache" \
      > "$npm_userconfig"

    export npm_config_prefix="$npm_prefix"
    export npm_config_cache="$npm_cache"
    export npm_config_userconfig="$npm_userconfig"
    export NPM_CONFIG_USERCONFIG="$npm_userconfig"

    exec ${lib.getExe llmAgentsPi} "$@"
  '';
}
