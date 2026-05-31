{
  flake.modules.homeManager.terminal =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        eza
        ripgrep
        fd
        fzf
        zoxide
        yazi
        jq
        nil
      ];
    };
}
