# Module conventions

This tree uses flake-parts with `import-tree`. Organize modules by semantic feature/aspect first, target class second.

## Rules

1. Features own all class aspects they need: `flake.modules.nixos.*`, `flake.modules.darwin.*`, `flake.modules.homeManager.*`, `flake.modules.hjem.*`, `perSystem`, packages, and related constants.
2. Names use slash classes: `feature/...`, `profile/...`, `user/...`, and `host/...`.
3. Profiles are import-only composition aspects. Hjem selector schema is internal config because extraModules are global; it is not a profile. Hosts are final composition aspects; host fragments stay explicit.
4. Aggregates are inheritance aspects with minimal direct config.
5. Use `config.flake` (often aliased as `flake`) for public flake outputs such as `flake.modules`, `flake.packages`, and `flake.lib`.
6. Use private module configuration through `config.<namespace>`; public values belong in `config.flake` outputs. Use `self` only for source-tree paths, for example `${self}/.agents/skills`.
7. Prefer small feature files over platform buckets. Platform folders are only for true platform foundation code.
