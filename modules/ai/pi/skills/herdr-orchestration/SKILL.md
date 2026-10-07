---
name: herdr-orchestration
description: "Use when doing work through subagents in herdr"
---

Orchestrate and coordinate work using focused subagents through `pi-herdr-subagents`. This keeps the context clean and focused, and matches each task to the role that fits it.

## Roles

| Role | Use for |
| --- | --- |
| `scout` | codebase reconnaissance: entry points, call paths, tests, conventions |
| `researcher` | external facts: upstream docs, release notes, API references, issue threads |
| `planner` | implementation plan for work that is not yet written |
| `oracle` | second opinion on a plan, a proposal, a design, or a decision already on the table |
| `worker` | default implementation with settled requirements and design, including multi-file changes |
| `engineer` | well-defined tasks whose implementation approach cannot be established without doing the work |
| `deep-reviewer` | deep review of a diff, PR, or issue; the merge gate |
| `fast-reviewer` | first pass over a diff: local defects only |
| `verifier` | reproduce a bug, run the tests, exercise the real surface |

Each role's model, thinking level, and tools come from its agent definition. Do not pass them when spawning.

## Picking a role

- Implement small tasks directly when their context is already available. Delegate only for a concrete benefit: context isolation, independent parallel work, or specialized tools.
- Evaluate model routing against task quality and total completion cost. Establish a capable baseline for uncertain work, then substitute cheaper models where they meet acceptance criteria.
- Need facts about this repository: `scout`. Need facts outside it: `researcher`.
- Resolve requirements and design before delegating implementation. Plan yourself when capable; use `planner` when you need implementation planning, and `oracle` when a second opinion can resolve an unsettled decision. Code exists and needs judgement: `deep-reviewer`.
- For delegated implementation with an established approach, default to `worker`, including multi-file and correctness-critical changes.
- Use `engineer` when the task is well-defined but its implementation approach is hard to establish in advance, including through planning or `oracle`, without doing the work. Name that uncertainty in the task. File count alone is not a reason to escalate; a worker blocker must meet the same criterion.
- Match review depth to risk. A local, low-risk change needs only `fast-reviewer`. A change that touches a trust boundary, data, concurrency, or the design needs `deep-reviewer`. Do not route every diff through every reviewer.
- A review is not proof that the change runs. Workers run focused checks. Use an independent `verifier` for uncertain real-world behavior, security, concurrency, algorithms, or cross-package effects. After a minor fix, recheck findings and affected paths rather than repeating full reviews and suites. Focused iteration checks do not replace broader integration checks before delivery.

## Spawn rules

- Call `subagent` with a distinct display `name`, the exact `agent` role, and a self-contained `task`.
- Task contract: state the goal, allowed files, required and excluded behavior, acceptance cases, verified commands and working directory, and unresolved decisions. Keep it compact. For algorithms, include real failures, legitimate transitions to preserve, and the metric and threshold used to judge success.
- Check that the role's tools cover the task before spawning. A read-only role cannot edit. If the tools do not fit, pick another role or narrow the task.
- Prefer named agents over adhoc agents. If an adhoc agent requires a model override, use the full `<provider>/<id>` name, where the provider is `azure-openai-responses`, `anthropic`, or `deepseek`. Never use a bare model name, `openai/<model>`, or `openrouter/<model>`.
- MCP tools belong to the parent. A child has them only if its role declares `mcp`; do not add MCP to a child.
- Split broad work into bounded tasks that you can verify. Do not delegate the whole task to one child unless it is already narrow and well specified.
- Spawn independent tasks in parallel. All children share the working tree, so do not assign overlapping edits concurrently; `worker`, `engineer`, and `verifier` all write files.
- Limit concurrent writers by file ownership and shared interfaces; limit requests by provider capacity across sessions. Read-only work can use more concurrency when tasks are independent.
- Configured agents disable nested spawning as a local coordination policy. Keep implementation workers non-spawning. Any future exception needs tracked children, bounded ownership, and gathered results before the supervising child exits.

## Lifecycle

- `subagent` returns immediately. Its acknowledgement is not the result.
- Do not poll, sleep, inspect session files, or call `subagents_list` to check progress. The extension delivers completion, failure, or `caller_ping` as a steer message and starts a new turn.
- Use `subagents_list` only to discover definitions when the configured roles above are insufficient.
- Inspect a child's work yourself, briefly: read the diff, the changed files, or the cited evidence. Do not rely on the summary alone.
- After two unsuccessful correction rounds, reassess requirements, design, implementation, environment, and role. This triggers reconsideration, not abandonment or a ban on further work.
- After a material redesign or accumulated failed approaches, prefer a fresh bounded session with an explicit handoff. Preserve useful state rather than resetting solely because the history is long.
- Handoff: goal and acceptance checks; branch, revision, and changed files; binding decisions and reasons; known failures and unresolved questions; exact verification commands; evidence locations; next bounded task.
- On `caller_ping`, call `subagent_resume` with the supplied `sessionPath` and your answer in `message`. Its default `autoExit: true` is correct for autonomous follow-up work.
- Use `subagent_interrupt` only to send Escape to a running turn. It does not terminate the child or produce a result by itself.
- Do not infer or summarize a child's result before its steer message arrives.
