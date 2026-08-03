{ config, ... }:
let
  zshBaseInit = ''
    setopt autocd
    zstyle ':autocomplete:*' list-lines 5

    ${builtins.readFile ../../dotfiles/init.zsh}

    eval "$(zoxide init zsh)"
    eval "$(wt config shell init zsh)"

    if [[ $options[zle] = on ]]; then
      source <(fzf --zsh)
    fi
  '';
in
{
  flake.modules.nixos."feature/shell/zsh" =
    { config, lib, ... }:
    let
      user = lib.attrByPath [ "nixComputers" "primaryUser" ] null config;
      hjemLoadEnv =
        if user == null then
          null
        else
          lib.attrByPath [ "hjem" "users" user "environment" "loadEnv" ] null config;
      hjemInit = lib.optionalString (hjemLoadEnv != null) ''
        source ${hjemLoadEnv}
      '';
    in
    {
      programs.zsh = {
        enable = true;
        autosuggestions.enable = true;
        syntaxHighlighting.enable = true;
        interactiveShellInit = hjemInit + zshBaseInit;
      };
    };

  flake.modules.darwin."feature/shell/zsh" =
    { config, lib, ... }:
    let
      user = lib.attrByPath [ "system" "primaryUser" ] null config;
      hjemLoadEnv =
        if user == null then
          null
        else
          lib.attrByPath [ "hjem" "users" user "environment" "loadEnv" ] null config;
      hjemInit = lib.optionalString (hjemLoadEnv != null) ''
        source ${hjemLoadEnv}
      '';
    in
    {
      programs.zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
        interactiveShellInit = hjemInit + zshBaseInit;
        promptInit = ''
          if [[ $TERM != "dumb" ]]; then
            eval "$(starship init zsh)"
          fi
        '';
      };
    };
}
