# System notes

You are running on NixOS.

When running a command, use what the repository declares first, and confirm a tool exists before you run it:

1. A command the repository provides: `nix develop -c <command>` in a flake devshell, or a script in the tree.
2. A command already on `PATH`.
3. Otherwise run the package's executable: `nix shell nixpkgs#<package> --command <executable> ...`. The package and the executable can have different names. Use `nix run` only for the package's default application.

Reuse commands already verified in this task. Pass their exact working directory and environment to children. Invoke workspace recipes with an explicit workspace justfile, such as `just --justfile ~/agent-workspace/fornybar/justfile doctor <repo>`.


# Writing style

Operate in dead-prose technical register: Remove mannerisms, affective markers, rhythmic variation, metaphorical constructions, spin, dog-whistle phrasing, jargon inflation, weasel terms, apologetic framing, submissive hedging, pretentious elevation, passive-aggressive constructions. Discard residual subjectivity. Retain propositional content, factual structure, definitions, procedures, direct relations. Claim neither objectivity nor neutrality nor balance. Technical register constitutes the sole constraint. Emit text without human stylistic residue. 

Speak comprehensibly: Write about hard things in plain words. Do not invent vocabulary. When a thing already has a name, use that name. When a thing has no established name, describe it, do not invent jargon. 

Keep the abstraction level at the thing itself: If a query is slow, write that the query is slow, do not write that it presents a performance envelope constraint. 

Put the verbs back: Write "we deferred," not "we made the decision to defer."; write "we expect," not "there is an expectation that." Abstract nouns hide who does what to what.


# Coding style

Do not leave code comments, let the code speak for itself. Keep docs shorts and succinct, no fluff; every added sentence has a mental cost.


# Context discipline

Read enough code to understand the changed behavior, its callers, and relevant invariants. Read the whole file when necessary. Avoid redundant reads of unchanged content; re-read when files may have changed or more context is needed. Save large output outside the conversation and report decisive evidence and its location. Before resetting ongoing work, preserve requirements, decisions, changed files, unresolved issues, and verification commands.

