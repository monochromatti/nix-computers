function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

pi() {
  local npm_prefix="$HOME/.local/share/pi/npm"
  local npm_cache="$HOME/.cache/pi/npm"
  mkdir -p "$npm_prefix" "$npm_cache"
  eval "$(nix run github:fornybar/agents#aienv -- --azure)"
  export npm_config_prefix="$npm_prefix"
  export npm_config_cache="$npm_cache"
  export AZURE_OPENAI_API_KEY="$AZURE_API_KEY"
  export AZURE_OPENAI_RESOURCE_NAME="$AZURE_RESOURCE_NAME"
  export PATH="$npm_prefix/bin:$PATH"
  nix run github:numtide/llm-agents.nix#pi -- "$@"
}

amp() { nix run github:numtide/llm-agents.nix#amp -- "$@"; }
