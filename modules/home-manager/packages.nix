{ inputs, ... }:
{
  flake.modules.homeManager.development =
    {
      pkgs,
      upkgs,
      ...
    }:
    let
      daily-hours = inputs.daily-hours.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      home.packages = [
        daily-hours

        # Nix
        pkgs.nixfmt-rfc-style
        pkgs.nixpkgs-fmt
        pkgs.nixd

        # Rust
        pkgs.rust-analyzer
        pkgs.cargo

        # Python
        upkgs.uv
        upkgs.ty
        upkgs.ruff

        # JavaScript
        upkgs.nodejs_24

        # Dev
        pkgs.gh
        pkgs.git
        upkgs.devenv

        # AI
        upkgs.rtk
      ];
    };

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

  flake.modules.homeManager.documents =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        glow
        pandoc
      ];
    };

  flake.modules.homeManager.publishing =
    { pkgs, ... }:
    let
      latex = pkgs.texliveMedium.withPackages (ps: with ps; [ arara ]);
    in
    {
      home.packages = [
        pkgs.quarto
        latex
      ];
    };

  flake.modules.homeManager.diagrams =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        d2
        silicon
      ];
    };

  flake.modules.homeManager.containers =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        docker
        docker-compose
      ];
    };

  flake.modules.homeManager.cloud =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        azure-cli
      ];
    };

  flake.modules.homeManager.virtualization =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        qemu
      ];
    };

  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    let
      niri-stack = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.niri-stack;
    in
    {
      home.packages = [ niri-stack ];
    };

  flake.modules.homeManager.security =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        bitwarden-desktop
      ];
    };

  flake.modules.homeManager.apps =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Terminal
        wl-clipboard

        # UI programs
        spotify
        kdePackages.okular
        libreoffice
        keymapp

        # Text editors
        obsidian

        # Graphics
        inkscape
        gimp

        # NATS
        natscli
        nsc

        # Other
        gpu-screen-recorder
        sqlite
      ];
    };

  flake.modules.homeManager.wsl = {
    imports = with inputs.self.modules.homeManager; [
      development
      terminal
      documents
    ];
  };

  flake.modules.homeManager.workstation = {
    imports = with inputs.self.modules.homeManager; [
      development
      terminal
      documents
      publishing
      diagrams
      containers
      cloud
      virtualization
    ];
  };

  flake.modules.homeManager.packages = {
    imports = with inputs.self.modules.homeManager; [
      workstation
      desktop
      security
    ];
  };

  flake.modules.nixos.packages = {
    home-manager.sharedModules = [
      inputs.self.modules.homeManager.apps
    ];
  };
}
