# Dendritic module conventions

This tree uses flake-parts with `import-tree`. Organize modules by semantic feature/aspect first, target class second.

## Rules

1. A feature owns all class aspects it needs: `flake.modules.nixos.*`, `flake.modules.darwin.*`, `flake.modules.homeManager.*`, `perSystem`, packages, and related flake constants.
2. Hosts are final composition aspects. Host modules should import reusable features and keep host-specific settings local.
3. Aggregates are inheritance aspects: mostly `imports`, minimal direct config.
4. Use `config.flake` (often aliased as `flake`) for flake outputs such as `flake.modules`, `flake.packages`, and `flake.lib`.
5. Use `self` only for source-tree paths, for example `${self}/.agents/skills`.
6. Do not use `inputs.self` for output references.
7. Prefer small feature files over platform buckets. Platform folders are only for true platform foundation code.

## Common aspect patterns here

- Simple aspects: shell pieces, package groups, desktop apps.
- Multi-context aspects: users, secrets, AI/system integration.
- Inheritance aspects: `shell`, `base`, wsl/package profiles, hosts.
- Conditional aspects: Home Manager desktop modules that differ by Linux/Darwin.
- Factory/library aspects: `flake.lib.mkNixos`, `flake.lib.mkDarwin`, package set helpers.

## Naming

`flake.modules.homeManager` is flat. Use clear names for feature groups and profiles, and prefer preserving public aspect names during refactors.
