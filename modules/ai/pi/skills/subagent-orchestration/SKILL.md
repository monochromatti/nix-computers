---
name: subagent-orchestration
description: "Use when choosing a subagent role or launching, steering, resuming, or stopping subagents"
---

## Roles

| Role | Use for |
| --- | --- |
| `scout` | codebase reconnaissance: entry points, call paths, tests, conventions |
| `visual-scout` | reconnaissance that requires inspecting images |
| `researcher` | external facts: upstream docs, release notes, API references, issue threads |
| `planner` | implementation plan for work not yet written |
| `oracle` | second opinion on a plan, design, or decision already on the table |
| `worker` | implementation with settled requirements and design, including multi-file changes |
| `engineer` | well-defined tasks whose approach cannot be established without doing the work; name that uncertainty in the task |
| `deep-reviewer` | review of a diff, PR, or issue touching a trust boundary, data, concurrency, or design; the merge gate |
| `fast-reviewer` | first pass over a diff: local defects only |
| `verifier` | reproduce a bug, run the tests, exercise the real surface |

Role model, thinking level, and tools come from the agent definition; do not pass them when spawning. DeepSeek roles (`scout`, `worker`, `fast-reviewer`) are text-only; vision needs `visual-scout` or another vision-capable role.

## Spawning

- `subagent({ agent, task })` takes the role in `agent` and a self-contained `task`: scope, acceptance checks, file ownership, verified commands, unresolved decisions. Launches are background by default; pass `async: false` only when the next step needs the result. Call `subagents_enable({})` first if `subagent` is not active.
- Do not pass `model` or thinking; the role sets them, and an override breaks its cost tuning. Do not nest: each level repeats the brief and report overhead.
- Agents share the working directory; assign disjoint files, or concurrent edits overwrite each other.
- Review depth follows risk: `fast-reviewer` for local low-risk changes, `deep-reviewer` for the rest, one reviewer per diff. A review does not prove the change runs; use `verifier` for uncertain real-world behavior, and recheck only affected paths after a minor fix; run the broader integration checks once before delivery.

## Lifecycle

- `bg_wait` collects background results; `{ action: "status", id }` inspects a run; `steer` redirects a live run; `resume` with `id` and `message` continues a finished or paused run in its stored session; `stop` cancels.
- A blocked child asks via `contact_supervisor`; answer with `subagent_supervisor`.
- Set `options.maxOutput` or the child's `output` file when a result may be large; inline output enters your context and is re-sent every turn.
- Check the diff and cited evidence before accepting a result.
- After two failed correction rounds, reassess requirements, design, environment, and role; further rounds on the same brief repeat the same failure.
