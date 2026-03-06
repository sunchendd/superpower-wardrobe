import {
  analyzeGaps,
  analyzeSeasonal,
  analyzeStyle,
  buildDistribution,
  generateSuggestions,
  nextSeason,
  type ClothingItem,
} from "./purchase_logic.ts";

// ── Helper ──────────────────────────────────────────────────────────────

function makeItem(overrides: Partial<ClothingItem> & { id: string; category: string }): ClothingItem {
  return { color: "black", tags: ["casual"], style: "casual", ...overrides };
}

// ── buildDistribution ───────────────────────────────────────────────────

Deno.test("buildDistribution counts categories", () => {
  const items: ClothingItem[] = [
    makeItem({ id: "1", category: "tops" }),
    makeItem({ id: "2", category: "tops" }),
    makeItem({ id: "3", category: "bottoms" }),
  ];
  const dist = buildDistribution(items, "category");
  if (dist["tops"] !== 2) throw new Error(`expected tops=2, got ${dist["tops"]}`);
  if (dist["bottoms"] !== 1) throw new Error(`expected bottoms=1, got ${dist["bottoms"]}`);
});

Deno.test("buildDistribution handles empty array", () => {
  const dist = buildDistribution([], "category");
  if (Object.keys(dist).length !== 0) throw new Error("expected empty distribution");
});

// ── nextSeason ──────────────────────────────────────────────────────────

Deno.test("nextSeason Mar-May → summer", () => {
  for (const m of [3, 4, 5]) {
    if (nextSeason(m) !== "summer") throw new Error(`month ${m} should map to summer`);
  }
});

Deno.test("nextSeason Sep-Nov → winter", () => {
  for (const m of [9, 10, 11]) {
    if (nextSeason(m) !== "winter") throw new Error(`month ${m} should map to winter`);
  }
});

Deno.test("nextSeason Jun-Aug → autumn", () => {
  for (const m of [6, 7, 8]) {
    if (nextSeason(m) !== "autumn") throw new Error(`month ${m} should map to autumn`);
  }
});

Deno.test("nextSeason Dec-Feb → spring", () => {
  for (const m of [12, 1, 2]) {
    if (nextSeason(m) !== "spring") throw new Error(`month ${m} should map to spring`);
  }
});

// ── analyzeGaps ─────────────────────────────────────────────────────────

Deno.test("analyzeGaps flags missing categories", () => {
  const items: ClothingItem[] = Array.from({ length: 10 }, (_, i) =>
    makeItem({ id: `t${i}`, category: "tops" })
  );
  const recs = analyzeGaps(items, ["tops", "bottoms", "outerwear", "shoes", "accessories"]);
  const cats = recs.map((r) => r.category);
  if (!cats.includes("bottoms")) throw new Error("should flag bottoms");
  if (!cats.includes("shoes")) throw new Error("should flag shoes");
  if (cats.includes("tops")) throw new Error("should not flag tops");
});

Deno.test("analyzeGaps returns empty for balanced wardrobe", () => {
  const items: ClothingItem[] = [
    ...Array.from({ length: 7 }, (_, i) => makeItem({ id: `t${i}`, category: "tops" })),
    ...Array.from({ length: 5 }, (_, i) => makeItem({ id: `b${i}`, category: "bottoms" })),
    ...Array.from({ length: 3 }, (_, i) => makeItem({ id: `o${i}`, category: "outerwear" })),
    ...Array.from({ length: 3 }, (_, i) => makeItem({ id: `s${i}`, category: "shoes" })),
    ...Array.from({ length: 2 }, (_, i) => makeItem({ id: `a${i}`, category: "accessories" })),
  ];
  const recs = analyzeGaps(items, ["tops", "bottoms", "outerwear", "shoes", "accessories"]);
  if (recs.length !== 0) throw new Error(`expected 0 gap recs, got ${recs.length}`);
});

Deno.test("analyzeGaps handles empty wardrobe", () => {
  const recs = analyzeGaps([], ["tops", "bottoms"]);
  if (recs.length === 0) throw new Error("empty wardrobe should produce recommendations");
  for (const r of recs) {
    if (r.reason !== "wardrobe_gap") throw new Error("reason should be wardrobe_gap");
  }
});

// ── analyzeSeasonal ─────────────────────────────────────────────────────

Deno.test("analyzeSeasonal suggests items when few seasonal pieces", () => {
  const items: ClothingItem[] = [
    makeItem({ id: "1", category: "tops", season: "winter" }),
  ];
  // March → summer; only 1 item is non-summer → should recommend
  const recs = analyzeSeasonal(items, 3);
  if (recs.length === 0) throw new Error("should suggest summer items");
  if (recs[0].season !== "summer") throw new Error("season should be summer");
  if (recs[0].reason !== "seasonal") throw new Error("reason should be seasonal");
});

Deno.test("analyzeSeasonal returns empty when enough seasonal items", () => {
  const items: ClothingItem[] = [
    makeItem({ id: "1", category: "tops", season: "summer" }),
    makeItem({ id: "2", category: "bottoms", season: "summer" }),
    makeItem({ id: "3", category: "shoes", season: "all" }),
  ];
  const recs = analyzeSeasonal(items, 3);
  if (recs.length !== 0) throw new Error(`expected 0, got ${recs.length}`);
});

// ── analyzeStyle ────────────────────────────────────────────────────────

Deno.test("analyzeStyle suggests formal when >70% casual", () => {
  const items: ClothingItem[] = Array.from({ length: 10 }, (_, i) =>
    makeItem({ id: `c${i}`, category: "tops", style: "casual" })
  );
  const recs = analyzeStyle(items, ["casual"]);
  const hasStyleMatch = recs.some((r) => r.reason === "style_match" && r.style_tags.includes("formal"));
  if (!hasStyleMatch) throw new Error("should suggest formal items");
});

Deno.test("analyzeStyle suggests contrasting colors for monotone wardrobe", () => {
  const items: ClothingItem[] = Array.from({ length: 10 }, (_, i) =>
    makeItem({ id: `b${i}`, category: "tops", color: "black" })
  );
  const recs = analyzeStyle(items, []);
  const colorRec = recs.find((r) => r.description.includes("颜色偏单一"));
  if (!colorRec) throw new Error("should flag monotone color palette");
});

Deno.test("analyzeStyle returns empty for diverse wardrobe", () => {
  const styles = ["casual", "formal", "streetwear", "sporty"];
  const colors = ["black", "white", "blue", "red", "green"];
  const items: ClothingItem[] = Array.from({ length: 10 }, (_, i) =>
    makeItem({
      id: `d${i}`,
      category: "tops",
      style: styles[i % styles.length],
      color: colors[i % colors.length],
    })
  );
  const recs = analyzeStyle(items, ["casual"]);
  if (recs.length !== 0) throw new Error(`expected 0 recs, got ${recs.length}`);
});

// ── generateSuggestions (integration) ───────────────────────────────────

Deno.test("generateSuggestions returns complete result structure", () => {
  const items: ClothingItem[] = [
    makeItem({ id: "1", category: "tops", color: "black", style: "casual" }),
    makeItem({ id: "2", category: "tops", color: "black", style: "casual" }),
  ];
  const result = generateSuggestions(
    items,
    { style_preferences: ["casual"] },
    [{ id: "c1", name: "tops" }, { id: "c2", name: "bottoms" }],
    4,
  );

  if (typeof result.analysis.total_items !== "number") throw new Error("missing total_items");
  if (!result.analysis.category_distribution) throw new Error("missing category_distribution");
  if (!result.analysis.color_distribution) throw new Error("missing color_distribution");
  if (!Array.isArray(result.analysis.top_missing)) throw new Error("missing top_missing");
  if (!Array.isArray(result.recommendations)) throw new Error("missing recommendations");
});

Deno.test("generateSuggestions de-duplicates by category+reason", () => {
  const items: ClothingItem[] = [];
  const result = generateSuggestions(
    items,
    {},
    [{ id: "c1", name: "tops" }, { id: "c2", name: "bottoms" }],
    4,
  );

  const keys = result.recommendations.map((r) => `${r.category}:${r.reason}`);
  const unique = new Set(keys);
  if (keys.length !== unique.size) throw new Error("recommendations contain duplicates");
});

Deno.test("generateSuggestions sorts by priority descending", () => {
  const items: ClothingItem[] = Array.from({ length: 10 }, (_, i) =>
    makeItem({ id: `t${i}`, category: "tops", color: "black", style: "casual" })
  );
  const result = generateSuggestions(
    items,
    { style_preferences: ["casual"] },
    [{ id: "c1", name: "tops" }, { id: "c2", name: "bottoms" }, { id: "c3", name: "shoes" }],
    10,
  );

  for (let i = 1; i < result.recommendations.length; i++) {
    if (result.recommendations[i].priority > result.recommendations[i - 1].priority) {
      throw new Error("recommendations not sorted by priority");
    }
  }
});

console.log("\nAll purchase_logic tests completed!");
