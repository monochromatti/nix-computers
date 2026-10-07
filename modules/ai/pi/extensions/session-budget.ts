import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { measureUsage, crossedThresholds } from "./session-budget-usage.ts";

export default function (pi: ExtensionAPI) {
  let warned = new Set<string>();
  const limits = {
    context: Number(process.env.PI_CONTEXT_WARNING_TOKENS ?? 100000),
    cost: Number(process.env.PI_SESSION_WARNING_USD ?? 10),
  };

  pi.on("session_start", () => {
    warned = new Set();
  });

  pi.on("message_end", (event, ctx) => {
    if (event.message.role !== "assistant") return;
    const usage = measureUsage(ctx.sessionManager.getEntries());
    const warnings = crossedThresholds(usage, limits, warned);
    for (const warning of warnings) {
      warned.add(warning);
      const message = warning === "context"
        ? `Context reached ${usage.context.toLocaleString()} tokens. Use narrower output or start a fresh bounded session after a redesign.`
        : `Recorded session cost reached $${usage.cost.toFixed(2)}. Reassess scope, blockers, and model selection before continuing.`;
      pi.sendMessage({ customType: "session-budget", content: message, display: true }, { triggerTurn: false });
      if (ctx.hasUI) ctx.ui.notify(message, "warning");
    }
  });

  pi.registerCommand("session-budget", {
    description: "Show recorded session cost and latest request context",
    handler: async (_args, ctx) => {
      const usage = measureUsage(ctx.sessionManager.getEntries());
      pi.sendMessage({
        customType: "session-budget",
        content: `Recorded session cost: $${usage.cost.toFixed(2)}; latest request context: ${usage.context.toLocaleString()} tokens. Includes inherited history; excludes other sessions and non-token charges.`,
        display: true,
      }, { triggerTurn: false });
    },
  });
}
