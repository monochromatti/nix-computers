---
name: herdr-orchestration
description: "Use when doing work through subagents in herdr"
---

Orchestrate and coordinate work using focused subagents through `pi-herdr-subagents`. This keeps the context clean and focused, and helps match the task difficulty to a suitable model to save costs and increase speed.

## Roles

| Role | Use for | Model |
| --- | --- | --- |
| `scout` | codebase reconnaissance: entry points, call paths, tests, conventions | DeepSeek-V4.1-Flash, low |
| `researcher` | external facts: upstream docs, release notes, API references, issue threads | gpt-6-luna, low |
| `planner` | implementation plan for work that is not yet written | gpt-6.1-sol, high |
| `oracle` | second opinion on a plan, a proposal, a design, or a decision already on the table | claude-opus-5-5, medium |
| `worker` | default implementation with settled requirements and design, including multi-file changes | DeepSeek-V4.1-Flash, high |
| `engineer` | well-defined tasks whose implementation approach cannot be established without doing the work | gpt-6.1-sol, low |
| `deep-reviewer` | deep review of a diff, PR, or issue; the merge gate | gpt-6.1-sol, medium |
| `fast-reviewer` | first pass over a diff: local defects only | DeepSeek-V4.1-Flash, high |
| `verifier` | reproduce a bug, run the tests, exercise the real surface | claude-sonnet-5, high |

## Picking a role

- Need facts about this repository: `scout`. Need facts outside it: `researcher`.
- Resolve requirements and design before delegating implementation. Plan yourself when capable; use `planner` when you need implementation planning, and `oracle` when a second opinion can resolve an unsettled decision. Code exists and needs judgement: `deep-reviewer`.
- Default to `worker` for implementation, including multi-file and correctness-critical changes with an established approach.
- Use `engineer` when the task is well-defined but its implementation approach is hard to establish in advance, including through planning or `oracle`, without doing the work. Name that uncertainty in the task. File count alone is not a reason to escalate; a worker blocker must meet the same criterion.
- Written change: `deep-reviewer` reads it, `verifier` runs it. Both are needed for a change that claims to work; a review is not proof that it runs.
- Review depth: `fast-reviewer` on every diff, to catch local defects while the change is fresh. `deep-reviewer` before a PR, a merge, or any change whose correctness depends on the design. A fast review never replaces the deep one.

## Spawn rules

- Call `subagent` with a distinct display `name`, the exact `agent` role, and a self-contained `task`.
- Include scope, constraints, expected output, and verification requirements in the task.
- For named agents, do not pass `model`, `tools`, or `skills`; the agent definition owns them.
- Prefer named agents over adhoc agents. If an adhoc agent requires a model override, use the full `<provider>/<id>` name, where the provider is `azure-openai-responses`, `anthropic`, or `deepseek`. Never use a bare model name, `openai/<model>`, or `openrouter/<model>`.
- Split broad work into bounded tasks that you can verify. Do not delegate the whole task to one child unless it is already narrow and well specified.
- Spawn independent tasks in parallel. All children share the working tree, so do not assign overlapping edits concurrently; `worker`, `engineer`, and `verifier` all write files.
- Stay below 3 concurrent subagents. If your instinct is to spawn more, the tasks are too small.

## Lifecycle

- `subagent` returns immediately. Its acknowledgement is not the result.
- Do not poll, sleep, inspect session files, or call `subagents_list` to check progress. The extension delivers completion, failure, or `caller_ping` as a steer message and starts a new turn.
- Use `subagents_list` only to discover definitions when the configured roles above are insufficient.
- On `caller_ping`, call `subagent_resume` with the supplied `sessionPath` and your answer in `message`. Its default `autoExit: true` is correct for autonomous follow-up work.
- Use `subagent_interrupt` only to send Escape to a running turn. It does not terminate the child or produce a result by itself.
- Do not infer or summarize a child's result before its steer message arrives.
