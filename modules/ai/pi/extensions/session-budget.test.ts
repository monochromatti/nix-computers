import assert from "node:assert/strict";
import { test } from "node:test";
import { measureUsage, crossedThresholds } from "./session-budget-usage.ts";
import sessionBudget from "./session-budget.ts";

const entry = (id: string, cost: number, input: number) => ({
  id,
  type: "message",
  message: { role: "assistant", usage: { input, cacheRead: 20, cacheWrite: 5, cost: { total: cost } } },
});

test("usage deduplicates copied entries and retains context after an empty error", () => {
  assert.deepEqual(measureUsage([
    entry("a", 1, 100), entry("a", 1, 100), entry("b", 2, 200),
    { id: "c", type: "message", message: { role: "assistant", usage: {} } },
    { id: "d", type: "message", message: { role: "user" } },
  ]), { cost: 3, context: 225 });
});

test("warnings trigger once and invalid or disabled limits do not trigger", () => {
  const usage = { cost: 10, context: 100000 };
  assert.deepEqual(crossedThresholds(usage, { cost: 10, context: 100000 }, new Set()), ["cost", "context"]);
  assert.deepEqual(crossedThresholds(usage, { cost: 10, context: 100000 }, new Set(["cost", "context"])), []);
  assert.deepEqual(crossedThresholds(usage, { cost: NaN, context: 0 }, new Set()), []);
});

test("extension reports warnings and exposes the session-budget command", async () => {
  const handlers = new Map<string, Function>();
  const commands = new Map<string, { handler: Function }>();
  const messages: { content: string }[] = [];
  sessionBudget({
    on: (name: string, handler: Function) => handlers.set(name, handler),
    registerCommand: (name: string, command: { handler: Function }) => commands.set(name, command),
    sendMessage: (message: { content: string }) => messages.push(message),
  } as never);
  const ctx = { sessionManager: { getEntries: () => [entry("a", 1000000, 1000000000)] }, hasUI: false };
  handlers.get("session_start")!();
  handlers.get("message_end")!({ message: { role: "user" } }, ctx);
  assert.equal(messages.length, 0);
  handlers.get("message_end")!({ message: { role: "assistant" } }, ctx);
  assert.equal(messages.length, 2);
  handlers.get("message_end")!({ message: { role: "assistant" } }, ctx);
  assert.equal(messages.length, 2);
  await commands.get("session-budget")!.handler("", ctx);
  assert.match(messages.at(-1)!.content, /excludes other sessions/);
});
