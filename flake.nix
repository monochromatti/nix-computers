{
  description = "Unified nix-darwin and NixOS configuration";

  nixConfig.flake-registry = "https://raw.githubusercontent.com/fornybar/registry/nixos-25.11/registry.json";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    llm-agents.url = "github:numtide/llm-agents.nix";
    agents = {
      url = "github:fornybar/agents/wrappers";
      inputs.llm-agents.follows = "llm-agents";
      inputs.nixpkgs.follows = "llm-agents/nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    daily-hours = {
      url = "github:monochromatti/daily-hours";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-specific inputs
    pc = {
      url = "github:fornybar/pc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    utgard = {
      url = "github:fornybar/utgard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./modules);
}
