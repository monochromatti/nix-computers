---
name: subagent-orchestration
description: "Use when delegating work through pi-subagent-manager"
---

Orchestrate and coordinate work using focused subagents through `pi-subagent-manager`. This keeps the context clean and focused, and matches each task to the role that fits it.

## Roles

| Role | Use for |
| --- | --- |
| `scout` | codebase reconnaissance: entry points, call paths, tests, conventions |
| `visual-scout` | reconnaissance that requires inspecting images |
| `researcher` | external facts: upstream docs, release notes, API references, issue threads |
| `planner` | implementation plan for work that is not yet written |
| `oracle` | second opinion on a plan, a proposal, a design, or a decision already on the table |
| `worker` | default implementation with settled requirements and design, including multi-file changes |
| `engineer` | well-defined tasks whose implementation approach cannot be established without doing the work |
| `deep-reviewer` | deep review of a diff, PR, or issue; the merge gate |
| `fast-reviewer` | first pass over a diff: local defects only |
| `verifier` | reproduce a bug, run the tests, exercise the real surface |

Prefer these custom roles over bundled roles. Each role's model, thinking level, and tools come from its agent definition. Do not pass them when spawning.

Role model preferences use configured credentials, independently of `/scoped-models`. The main Pi default model remains separate. A role without `models` inherits its parent's model. Use `/agents` to override model selection and `/agents types` to override individual roles.

## Picking a role

- Implement small tasks directly when their context is already available. Delegate only for a concrete benefit: context isolation, independent parallel work, or specialized tools.
- Check `agent_types` before choosing a role. Image, screenshot, diagram, and visual-layout inspection require a vision-capable resolved model and suitable tools. DeepSeek roles (`scout`, `worker`, `fast-reviewer`) are text-only by default. Use `visual-scout` for visual reconnaissance, inspect the images yourself and pass a complete text specification, or choose another vision-capable role; this takes precedence over default role preferences. Do not infer vision support from a role name or provider alone.
- Evaluate model routing against task quality and total completion cost. Establish a capable baseline for uncertain work, then substitute cheaper models where they meet acceptance criteria.
- Need facts about this repository: `scout`. Need facts outside it: `researcher`.
- Resolve requirements and design before delegating implementation. Plan yourself when capable; use `planner` when you need implementation planning, and `oracle` when a second opinion can resolve an unsettled decision. Code exists and needs judgement: `deep-reviewer`.
- For delegated implementation with an established approach, default to `worker`, including multi-file and correctness-critical changes.
- Use `engineer` when the task is well-defined but its implementation approach is hard to establish in advance, including through planning or `oracle`, without doing the work. Name that uncertainty in the task. File count alone is not a reason to escalate; a worker blocker must meet the same criterion.
- Match review depth to risk. A local, low-risk change needs only `fast-reviewer`. A change that touches a trust boundary, data, concurrency, or the design needs `deep-reviewer`. Do not route every diff through every reviewer.
- A review is not proof that the change runs. Workers run focused checks. Use an independent `verifier` for uncertain real-world behavior, security, concurrency, algorithms, or cross-package effects. After a minor fix, recheck findings and affected paths rather than repeating full reviews and suites. Focused iteration checks do not replace broader integration checks before delivery.

## Spawn rules

- Call `agent_spawn` with a distinct task-based `path`, the exact role in `type`, and a self-contained `task`.
- Use fresh paths (`/task-name`) by default. Fork (`/root/task-name`) only when the child needs conversation history that a task description cannot carry. A fresh child sees only its task, so it stays focused, costs fewer tokens, and judges without inheriting the parent's assumptions.
- State scope, acceptance checks, file ownership, verified commands, and unresolved decisions before spawning.
- Launch independent siblings with `wait: false`, then use `agent_wait`. Agents share the working directory; do not assign overlapping edits.
- Custom roles cannot spawn children because their tool allowlists omit delegation tools.

## Lifecycle

- Detached completion starts a parent turn; do not poll session files.
- Use `agent_types` to discover definitions, `agent_output` to retrieve long results, and `agent_steer` to resume or redirect a thread by path.
- A blocked child reports with `agent_update`, calls `agent_pause`, and stops until instructed.
- Use `agent_stop` to cancel a child and its descendants.
- Inspect the diff and cited evidence before accepting a result.
- After two unsuccessful correction rounds, reassess requirements, design, environment, and role.
