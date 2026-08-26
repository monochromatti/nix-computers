---
description: Create git commits
argument-hint: "Additional instructions"
---

Create git commits from uncommitted changes. Leave temporary files uncommitted (build artifacts, or development documents and files).

Each commit should contain only thematically related changes, forming an atomic commit history. Commit scope should strike a balance between size (for a shorter history) and reviewability.

If uncommitted changes are fixes or modifications of changes already committed on the current feature branch, it is likely that the better option is to rub those changes into one or more existing commits. We do not want commits that fix earlier commits on the same feature branch, the history should read linearly.

Use Conventional Commits style, and leave a short message (<100 characters) on each commit motivating, explaining or justifying it. Use plain language, avoid obscure jargon.

$1
