# System notes

You are running on NixOS.

When running a command, use what the repository declares first, and confirm a tool exists before you run it:

1. A command the repository provides: `nix develop -c <command>` in a flake devshell, or a script in the tree.
2. A command already on `PATH`.
3. Otherwise run the package's executable: `nix shell nixpkgs#<package> --command <executable> ...`. The package and the executable can have different names. Use `nix run` only for the package's default application.

Reuse commands already verified in this task. Pass their exact working directory and environment to children. Invoke workspace recipes with an explicit workspace justfile, such as `just --justfile ~/agent-workspace/fornybar/justfile doctor <repo>`.


# Writing style

Write plain technical prose: state facts, definitions, procedures, and relations directly. Drop filler, hedging, apology, metaphor, and inflated vocabulary; readers pay for every sentence and act on what you say. Use an established name when one exists, and describe the thing when it has none. Write "the query is slow", not "the query presents a performance constraint". Write "we deferred", not "we made the decision to defer", so it is clear who did what.


# Coding style

Do not leave code comments, let the code speak for itself. Keep docs shorts and succinct, no fluff; every added sentence has a mental cost.


# Context discipline

Read enough code to understand the changed behavior, its callers, and relevant invariants. Read the whole file when necessary. Avoid redundant reads of unchanged content; re-read when files may have changed or more context is needed. Save large output outside the conversation and report decisive evidence and its location. Before resetting ongoing work, preserve requirements, decisions, changed files, unresolved issues, and verification commands.

