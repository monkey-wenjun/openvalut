/** Deterministic gradient + letter for an entry's favicon tile. */

const PALETTE: [string, string][] = [
  ["#4285f4", "#34a853"],
  ["#ff6a00", "#ee0979"],
  ["#2563eb", "#38bdf8"],
  ["#0e7490", "#06b6d4"],
  ["#7c3aed", "#a855f7"],
  ["#f43f5e", "#fb7185"],
  ["#059669", "#34d399"],
  ["#334155", "#64748b"],
  ["#d97706", "#fbbf24"],
];

export function entryVisual(seed: string): { background: string; letter: string } {
  let hash = 0;
  for (const c of seed) hash = (hash * 31 + c.charCodeAt(0)) >>> 0;
  const [from, to] = PALETTE[hash % PALETTE.length];
  return {
    background: `linear-gradient(135deg, ${from}, ${to})`,
    letter: (seed.trim()[0] ?? "?").toUpperCase(),
  };
}
