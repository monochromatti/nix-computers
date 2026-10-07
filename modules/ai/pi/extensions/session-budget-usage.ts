type Entry = {
  id?: string;
  type: string;
  message?: {
    role: string;
    usage?: {
      input?: number;
      cacheRead?: number;
      cacheWrite?: number;
      cost?: { total?: number };
    };
  };
};

export function measureUsage(entries: Entry[]) {
  const seen = new Set<string>();
  let cost = 0;
  let context = 0;
  for (const entry of entries) {
    if (entry.type !== "message" || entry.message?.role !== "assistant") continue;
    if (entry.id && seen.has(entry.id)) continue;
    if (entry.id) seen.add(entry.id);
    const usage = entry.message.usage;
    if (!usage) continue;
    cost += usage.cost?.total ?? 0;
    const tokens = (usage.input ?? 0) + (usage.cacheRead ?? 0) + (usage.cacheWrite ?? 0);
    if (tokens > 0) context = tokens;
  }
  return { cost, context };
}

export function crossedThresholds(
  usage: { cost: number; context: number },
  limits: { cost: number; context: number },
  warned: Set<string>,
) {
  return (["cost", "context"] as const).filter(
    key => Number.isFinite(limits[key]) && limits[key] > 0 && usage[key] >= limits[key] && !warned.has(key),
  );
}
