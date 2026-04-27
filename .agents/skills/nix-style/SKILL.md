---
name: nix-style
description: "Primes agents on this user's Nix language taste: function shape, currying vs attrsets, nesting, scope, data transforms, conditionals, merges, paths, shell snippets, and package expressions. Not a generic NixOS/flakes design guide."
disable-model-invocation: true
---

# Nix Language Style

Use this skill to write Nix that looks like this user wrote it. Formatting is not the point; assume `nixfmt-rfc-style`. Focus on expression shape, data flow, names, scope, and local idioms.

## Prime directive

Prefer Nix that is **direct, local, semantic, stable, honest**.

- **Direct:** plain expressions, direct booleans, direct attr access, `or` defaults.
- **Local:** source stays visible when it matters; avoid broad scope tricks.
- **Semantic:** bind concepts, not aliases; helpers named by role.
- **Stable:** prefer one readable attr shape with conditional leaves over branchy assembly.
- **Honest:** `//` means actual merging/preserving unknown attrs; otherwise write known shape.

This is Nix language taste, not broad module/flake architecture.

## Taste defaults

Apply these unless local code strongly argues otherwise.

### Function shape

- Package files and real helpers use closed attrsets.
- NixOS module entrypoints still use normal `{ config, lib, pkgs, ... }:`.
- Small scalar helpers curry when positions are obvious: `prefix: name: ...`, `host: port: ...`.
- Domain helpers and helpers with 3+ fields use closed attrset args; defaults go in parameter list.
- Callbacks over records keep the record whole: `user.name`, `user.shell or ...`; do not destructure callback args.
- Missing required fields can fail naturally. Add `throw` only at real enum/case fallbacks.

### Names and lets

- Good helper names: `mkUser`, `mkVhost`, `mkProxyPass`.
- Bad names: `f`, `mk`, huge names like `userToCompleteNixosUserConfiguration`.
- Inline tiny one-off lambdas.
- Extract larger lambdas, especially map bodies with several attrs.
- Bind major/reused concepts, not every intermediate.
- Bind repeated expressions around 3+ uses, or earlier if concept is central.

### Scope

- Keep `lib` qualified: `lib.mkIf`, `lib.optional`, `lib.mapAttrs`.
- Avoid `with lib;` and broad `inherit (lib)`.
- Common builtins can be unqualified: `map`, `filter`, `toString`, `throw`.
- Prefer `map` over `lib.forEach`.
- `with pkgs;` is good for package-only scopes.
- Mixed sources stay explicit: `pkgs.foo`, `inputs.foo`, `cfg.foo`.

### Attrsets

- Nest shared prefixes.
- Dotted leaves are fine for one deep value.
- Split where branch has several children.
- Dynamic attrs use `attrs.${name}`, not `attrs."${name}"`.
- Use `inherit pname version;` for same-name locals.
- Use `inherit (cfg)` only when whole attrset is cfg-sourced.
- Avoid `rec` in derivations. Plain-data `rec` is okay when it clearly saves duplication.

### Data flow

- Use `lib.pipe` for linear collection transforms.
- Extract larger map bodies into `mkThing` helpers.
- Prefer `builtins.listToAttrs` with `{ name; value; }` when source list already contains full records.
- Use `lib.mapAttrs'` + `lib.nameValuePair` for attrset key renames.
- Avoid lookup-based `genAttrs` when data already exists in list records.

### Conditionals and merging

- Direct booleans, not `if cond then true else false`.
- Prefer stable attr shapes with `null`/conditional leaves when types allow.
- Use `++ lib.optional ... ++ lib.optionals ...` for lists.
- Avoid `//` for construction. Use it only when absence is required or preserving unknown attrs is intent.
- In modules, use `lib.mkMerge`/`lib.mkIf` when disabled subtree must be absent or would be invalid.

### Paths, generated files, shell

- Direct paths stay paths: `imports = [ ./hardware-configuration.nix ];`.
- Subpaths from path vars may use interpolation: `"${dir}/nginx.nix"`.
- Generate JSON/YAML/etc with serializers: `builtins.toJSON`, `formats.*`, etc.
- Prefer `pkgs.writeShellApplication` with `runtimeInputs`; use bare command names in `text`.
- For raw snippets without `runtimeInputs`, store-path interpolation is good.

## Handpicked examples

### Small scalar helper vs domain helper

GOOD:

```nix
let
  mkProxyPass = host: port: "http://${host}:${toString port}";

  mkVhost =
    {
      domain,
      port,
      root,
      enableTls ? false,
    }:
    {
      inherit root;
      forceSSL = enableTls;
      enableACME = enableTls;
      locations."/".proxyPass = mkProxyPass "127.0.0.1" port;
    };
in
{
  services.nginx.virtualHosts.${domain} = mkVhost {
    inherit domain;
    inherit (cfg) port root enableTls;
  };
}
```

BAD:

```nix
let
  mkVhost = domain: port: root: enableTls: {
    inherit root;
    forceSSL = enableTls;
    enableACME = enableTls;
  };
in
mkVhost domain cfg.port cfg.root cfg.enableTls
```

### Callback records stay whole

GOOD:

```nix
map (user: {
  home = "/home/${user.name}";
  shell = user.shell or pkgs.bashInteractive;
  extraGroups = user.extraGroups or [ ];
}) users
```

BAD:

```nix
map (
  { name, shell ? pkgs.bashInteractive, extraGroups ? [ ], ... }:
  {
    home = "/home/${name}";
    inherit shell extraGroups;
  }
) users
```

### Scope and source visibility

GOOD:

```nix
{
  environment.systemPackages = with pkgs; [
    curl
    jq
    git
  ];

  services.postgresql.package = pkgs.postgresql_16;

  config = lib.mkIf cfg.enable {
    packages = [ pkgs.curl ] ++ lib.optional cfg.enableGit pkgs.git;
  };
}
```

GOOD mixed sources:

```nix
[
  pkgs.curl
  pkgs.jq
  inputs.my-tool.packages.${system}.default
]
```

BAD:

```nix
let
  inherit (lib) mkIf optional;
in
{
  config = mkIf cfg.enable {
    packages = [ pkgs.curl ] ++ optional cfg.enableGit pkgs.git;
  };

  mixedPackages = with pkgs; [
    curl
    jq
    inputs.my-tool.packages.${system}.default
  ];
}
```

### Nesting and dynamic attrs

GOOD:

```nix
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts.${domain}.locations."/".proxyPass = "http://127.0.0.1:3000";

    virtualHosts.${domain}.locations."/api" = {
      proxyPass = "http://127.0.0.1:4000";
      extraConfig = ''
        proxy_set_header X-API true;
      '';
    };
  };
}
```

BAD:

```nix
{
  services.nginx.enable = true;
  services.nginx.recommendedProxySettings = true;
  services.nginx.virtualHosts."${domain}".locations."/".proxyPass = "http://127.0.0.1:3000";
}
```

### Linear transforms

GOOD:

```nix
let
  mkUser = user: {
    name = user.name;
    value = {
      isNormalUser = true;
      home = "/home/${user.name}";
      shell = user.shell or pkgs.bashInteractive;
      extraGroups = user.extraGroups or [ ];
    };
  };

  usersByName =
    lib.pipe users [
      (filter (user: user.enable or true))
      (map mkUser)
      builtins.listToAttrs
    ];
in
{
  users.users = usersByName;
}
```

BAD lookup-heavy shape:

```nix
let
  usersByName = lib.genAttrs (map (user: user.name) users) (
    name: lib.findFirst (user: user.name == name) null users
  );
in
lib.mapAttrs mkUser usersByName
```

GOOD attrset rename with known shape:

```nix
lib.mapAttrs' (
  name: value:
  lib.nameValuePair "prefix-${name}" {
    port = value.port;
    host = value.host;
    enabled = true;
  }
) attrs
```

Only use this when preserving arbitrary attrs is intended:

```nix
value // {
  enabled = true;
}
```

### Stable conditionals over branchy assembly

GOOD:

```nix
{
  forceSSL = cfg.enableTls && cfg.domain != "localhost";

  settings = {
    port = cfg.port;
    tls.certFile = if cfg.enableTls then cfg.certFile else null;
  };

  packages =
    [
      pkgs.curl
      pkgs.jq
    ]
    ++ lib.optional cfg.enableGit pkgs.git
    ++ lib.optionals cfg.enableDev [
      pkgs.ripgrep
      pkgs.fd
    ];
}
```

BAD:

```nix
{
  forceSSL = if cfg.enableTls && cfg.domain != "localhost" then true else false;

  settings =
    {
      port = cfg.port;
    }
    // lib.optionalAttrs cfg.enableTls {
      tls.certFile = cfg.certFile;
    };
}
```

When module subtree must be absent, use module tools:

```nix
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.postgresql.enable = true;
    })

    (lib.mkIf (cfg.enable && cfg.enableMetrics) {
      services.prometheus.exporters.postgres = {
        enable = true;
        port = cfg.metricsPort;
        dataSourceName = cfg.metricsDsn;
      };
    })
  ];
}
```

### Package expression baseline

GOOD:

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
}:

let
  pname = "my-tool";
  version = "1.2.3";
in
rustPlatform.buildRustPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "acme";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-...";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];
  cargoHash = "sha256-...";

  meta = {
    description = "Small CLI tool";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
```

BAD:

```nix
{ pkgs }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "my-tool";
  version = "1.2.3";

  src = pkgs.fetchFromGitHub {
    owner = "acme";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-...";
  };

  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.openssl ];
  cargoHash = "sha256-...";

  meta.license = pkgs.lib.licenses.mit;
}
```

## Review checklist

- Closed package/helper args? Domain object attrs? Small scalar currying?
- Callback keeps records whole? Names short/descriptive?
- `lib.` qualified? Common builtins plain? `map` not `lib.forEach`?
- `with pkgs;` only package-only? Mixed sources explicit?
- Shared prefixes nested? Single deep values dotted? Dynamic attrs use `${name}`?
- `inherit` improves clarity? Derivations avoid `rec`?
- Linear transforms use `pipe`; large map bodies extracted?
- `//` only for real merge/preserve-unknown intent?
- Stable bool/null leaves used when valid? `mkIf`/`mkMerge` only when absence matters?
- Defaults use `or`; dynamic attrs use selector syntax?
- Structured config uses serializers? Shell apps use `writeShellApplication`?
