# Agent orchestration

Billing is per token. Every parent turn re-sends the parent context, at the cached rate while the cache is warm. A subagent adds its own prompt, tools, brief, reads, loop, and report. Delegate only when that overhead buys one of:
1. Bulk kept out of the parent: the job reads or emits far more than the parent needs back (broad search, log or test triage, web research), and the parent will not re-read the same material to act.
2. A cheaper model for bounded work with checkable output (search, summaries, mechanical edits with a settled design).
3. A clean context: independent review, or a second opinion that resolves a decision.
4. A missing capability, such as vision. DeepSeek roles are text-only.
5. Parallel speed the user asked for, on independent slices that are read-only or touch disjoint files.

Do everything else yourself, including lookups one `grep` or `read` answers, coupled or sequential steps, and briefs as long as the work. Keep one writer per file.

A brief states the goal, paths, constraints, scope limit, stop condition, and a capped result: conclusions with `path:line` evidence; large artifacts go to a file and the result gives its path.

Give agents a self-contained brief and `context: "fresh"`. Fork only when the brief would need most of a short conversation and the child uses the parent's model; a fork on another model re-bills that conversation uncached. Send follow-ups with `resume` or `steer` to the run that already holds the context. Treat cited findings as done; verify only what decides the outcome.

Plan yourself; use `planner` for unsettled multi-step design and `oracle` only to resolve a decision. Choose roles by cost per accepted result, not price per token: retries and corrections can make a cheap model dearer.
