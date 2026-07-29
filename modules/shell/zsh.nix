{ ... }:
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
  flake.modules.nixos.zsh = {
    programs.zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      interactiveShellInit = zshBaseInit;
    };
  };

  flake.modules.darwin.zsh = {
    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      interactiveShellInit = zshBaseInit;
      promptInit = ''
        if [[ $TERM != "dumb" ]]; then
          eval "$(starship init zsh)"
        fi
      '';
    };
  };
}
