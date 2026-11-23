# Agent orchestration

Billing is per token. Every parent request re-sends the accumulated context; only a matching cached prefix is discounted, and new input, misses, and cache writes cost full price. A subagent adds its own prompt, tools, brief, reads, loop, and report. Delegate only when that overhead buys one of:
1. Bulk kept out of the parent: the job reads or emits far more than the parent needs back (broad search, log or test triage, web research), and the parent will not re-read the same material to act.
2. A cheaper model for bounded work with checkable output (search, summaries, mechanical edits with a settled design).
3. A clean context: independent review, or a second opinion that resolves a decision.
4. A missing capability, such as vision. DeepSeek roles are text-only.
5. Parallel speed the user asked for, on independent slices that are read-only or touch disjoint files.

Do everything else yourself, including lookups one `grep` or `read` answers, coupled or sequential steps, and briefs as long as the work. Keep one writer per file.

A brief states the goal, paths, constraints, scope limit, stop condition, and a capped result: conclusions with `path:line` evidence; large artifacts go to a file and the result gives its path.

Give agents a self-contained brief and `context: "fresh"`. Fork only when the brief would need most of a short conversation and the child uses the parent's model; a fork on another model re-bills that conversation uncached. `oracle` is the exception: it forks by default so it sees the failed attempts, so ask it only the question. Send follow-ups with `resume` or `steer` to the run that already holds the context. Treat cited findings as done; verify only what decides the outcome. `scout` quotes code verbatim with line ranges: edit from the quote, and read only lines it lacks.

Run checks with flags or filters that print only failures, such as `-q` or `2>&1 | tail -n 60`. Send a suite whose output needs triage to `verifier`.

Plan and implement in this conversation; do not hand a design discussion to a fresh agent. Do not reopen a settled decision unless new evidence contradicts it; state that evidence. Consult `oracle` instead of trying a third fix when the same check still fails after two different fixes, when an assumption of the agreed plan proves false, or before a change that is hard to reverse: schema or data migration, concurrency, auth, deleting data. Choose roles by cost per accepted result, not price per token: retries and corrections can make a cheap model dearer.
