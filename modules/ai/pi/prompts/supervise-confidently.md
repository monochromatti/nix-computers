---
description: Supervise work with pi-herdr-subagents
argument-hint: "<task>"
---

Task: $@

Complete the task by coordinating focused subagents through `pi-herdr-subagents`.

## Roles

- `worker`: implementation
- `scout`: read-only codebase research
- `planner`: read-only implementation planning
- `reviewer`: read-only code review
- `quick-reviewer`: read-only review of code, plans, or proposed solutions
- `oracle`: read-only second opinion on difficult decisions

## Spawn rules

- Call `subagent` with a distinct display `name`, the exact `agent` role, and a self-contained `task`.
- Include scope, constraints, expected output, and verification requirements in the task.
- For named agents, do not pass `model`, `tools`, or `skills`; the agent definition owns them.
- Prefer named agents over ad hoc agents. If an ad hoc agent requires a model override, use `azure-openai-responses/<model>`. Never use a bare model name, `openai/<model>`, or `openrouter/<model>`.
- Spawn independent tasks in parallel. All children share the working tree, so do not assign overlapping edits concurrently.

## Lifecycle

- `subagent` returns immediately. Its acknowledgement is not the result.
- Do not poll, sleep, inspect session files, or call `subagents_list` to check progress. The extension delivers completion, failure, or `caller_ping` as a steer message and starts a new turn.
- Use `subagents_list` only to discover definitions when the configured roles above are insufficient.
- On `caller_ping`, call `subagent_resume` with the supplied `sessionPath` and your answer in `message`. Its default `autoExit: true` is correct for autonomous follow-up work.
- Use `subagent_interrupt` only to send Escape to a running turn. It does not terminate the child or produce a result by itself.
- Do not infer or summarize a child's result before its steer message arrives.

Review every result before relying on it. Run final integration checks yourself. Use `oracle` only when another view can change an unsettled decision.
