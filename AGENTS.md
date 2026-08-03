# AGENTS.md

Guidance for agents working in this repository.

## Scope

These instructions apply to the entire repository (this directory and all subdirectories).

## Repository Overview

This is a flake-based personal systems configuration repository for:

1. NixOS hosts
2. nix-darwin hosts
3. Home Manager modules
4. A small local package (`packages/daily-hours`)

The repository follows a modular style centered around `modules/` and assembled through `flake-parts` in `flake.nix`.

## Design Principles

1. Prefer dendritic Nix structure: treat each non-entry Nix file as a flake-parts/top-level module for one semantic feature, with that feature providing any NixOS, nix-darwin, Home Manager, or shared aspects it needs. Compose hosts from reusable features instead of scattering feature logic into host-specific trees.

## Structure

1. `flake.nix`: flake inputs and top-level outputs assembly.
2. `modules/`: main module tree (hosts, OS modules, users, Home Manager modules, package sets).
3. `dotfiles/`: shell and user environment dotfiles.
4. `packages/`: custom packages and scripts.
5. `modules/platform/secrets/`: sops-related definitions and encrypted data.

## Editing Guidelines

1. Keep modules small and composable; prefer adding focused module files over making one file do many things.
2. Preserve existing naming and layout conventions in `modules/`.
3. Avoid broad refactors unless explicitly requested.
4. Do not commit decrypted secret material or alter encryption workflows unless asked.
5. For scripts, favor clear, portable code and minimal dependencies.

## Formatting

1. Nix code is formatted with `nixfmt` via `treefmt-nix`.
2. Run formatting after edits that touch Nix files.

Suggested command:

```bash
nix fmt
```

## Validation

Run checks relevant to your change. Prefer quick, targeted validation first, then broader checks when needed.

Suggested commands:

```bash
nix flake check
```

If `nix flake check` is too heavy for the current task, at least evaluate the affected attribute(s) or host configuration.

## Change Discipline

1. Keep diffs minimal and task-focused.
2. Add brief comments only where logic is non-obvious.
3. Do not rewrite unrelated files.
4. When introducing new modules, place them in the most specific existing subtree and wire them in explicitly.
