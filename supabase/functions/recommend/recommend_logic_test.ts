import {
  buildRecommendation,
  buildMultipleRecommendations,
  getWeatherTag,
  scoreColorHarmony,
  scoreWearBalance,
  scoreStyleConsistency,
  scoreSeasonAppropriateness,
  scoreOutfit,
  buildReasonText,
  type ClothingItem,
} from "./recommend_logic.ts";

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(`FAIL: ${message}`);
  console.log(`PASS: ${message}`);
}

function assertApprox(actual: number, expected: number, epsilon: number, message: string) {
  if (Math.abs(actual - expected) > epsilon) {
    throw new Error(`FAIL: ${message} — expected ~${expected}, got ${actual}`);
  }
  console.log(`PASS: ${message}`);
}

// ═══ getWeatherTag (existing) ════════════════════════════════════════

assert(getWeatherTag(30) === "warm", "temp 30 -> warm");
assert(getWeatherTag(22) === "mild", "temp 22 -> mild");
assert(getWeatherTag(15) === "cool", "temp 15 -> cool");
assert(getWeatherTag(5) === "cold", "temp 5 -> cold");

// ═══ buildRecommendation backwards compat (existing) ═════════════════

const items: ClothingItem[] = [
  { id: "t1", category: "tops", color: "white", tags: ["casual"] },
  { id: "b1", category: "bottoms", color: "blue", tags: ["denim"] },
  { id: "s1", category: "shoes", color: "white", tags: ["casual"] },
];
const result1 = buildRecommendation(items, [], { temp: 22, condition: "clear" }, "casual");
assert(result1.source === "ai_generated", "wardrobe items -> ai_generated");
assert(result1.item_ids.length >= 2, "at least tops + bottoms");
assert(result1.item_ids.includes("t1"), "tops included");
assert(result1.item_ids.includes("b1"), "bottoms included");

// Test: fallback to preset when wardrobe has no bottoms
const itemsNoBottoms: ClothingItem[] = [
  { id: "t1", category: "tops", color: "white", tags: ["casual"] },
];
const presets = [
  { id: "p1", name: "牛仔裤 + 白T", categories: ["tops", "bottoms"], occasion: "casual", weather_tags: ["warm", "mild"] },
];
const result2 = buildRecommendation(itemsNoBottoms, presets, { temp: 22, condition: "clear" }, "casual");
assert(result2.source === "preset", "incomplete wardrobe -> preset fallback");
assert(result2.preset_id === "p1", "correct preset selected");

// Test: fallback to preset when wardrobe empty
const result3 = buildRecommendation([], presets, { temp: 25, condition: "sunny" }, "casual");
assert(result3.source === "preset", "empty wardrobe -> preset");

// ═══ Color Harmony Scoring ═══════════════════════════════════════════

const neutralPair: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [] },
  { id: "2", category: "bottoms", color: "black", tags: [] },
];
assertApprox(scoreColorHarmony(neutralPair), 0.9, 0.01, "neutral pair = 0.9");

const accentNeutral: ClothingItem[] = [
  { id: "1", category: "tops", color: "red", tags: [] },
  { id: "2", category: "bottoms", color: "black", tags: [] },
];
assertApprox(scoreColorHarmony(accentNeutral), 1.0, 0.01, "single accent + neutral = 1.0");

const clashingColors: ClothingItem[] = [
  { id: "1", category: "tops", color: "red", tags: [] },
  { id: "2", category: "bottoms", color: "blue", tags: [] },
];
assertApprox(scoreColorHarmony(clashingColors), 0.65, 0.01, "warm+cool no neutral = 0.65");

const bridgedComplementary: ClothingItem[] = [
  { id: "1", category: "tops", color: "red", tags: [] },
  { id: "2", category: "bottoms", color: "blue", tags: [] },
  { id: "3", category: "shoes", color: "white", tags: [] },
];
assertApprox(scoreColorHarmony(bridgedComplementary), 0.8, 0.01, "warm+cool+neutral = 0.8");

assert(scoreColorHarmony([neutralPair[0]]) === 1.0, "single item = 1.0");

// ═══ Wear Balance Scoring ════════════════════════════════════════════

const freshItems: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [], wear_count: 0 },
  { id: "2", category: "bottoms", color: "blue", tags: [], wear_count: 0 },
];
assertApprox(scoreWearBalance(freshItems), 1.0, 0.01, "zero wear counts = 1.0");

const wornItems: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [], wear_count: 10 },
  { id: "2", category: "bottoms", color: "blue", tags: [], wear_count: 10 },
];
assert(scoreWearBalance(wornItems) < scoreWearBalance(freshItems), "worn items score lower");
assert(scoreWearBalance(wornItems) > 0, "worn items still positive");

// ═══ Style Consistency Scoring ═══════════════════════════════════════

const consistentStyle: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [], style_tags: ["casual", "minimal"] },
  { id: "2", category: "bottoms", color: "blue", tags: [], style_tags: ["casual", "denim"] },
];
assert(scoreStyleConsistency(consistentStyle) > 0.5, "shared 'casual' tag > 0.5");

const mixedStyle: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [], style_tags: ["formal"] },
  { id: "2", category: "bottoms", color: "blue", tags: [], style_tags: ["streetwear"] },
];
assert(
  scoreStyleConsistency(mixedStyle) <= scoreStyleConsistency(consistentStyle),
  "mixed styles score <= consistent styles"
);

const noTags: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [] },
  { id: "2", category: "bottoms", color: "blue", tags: [] },
];
assertApprox(scoreStyleConsistency(noTags), 0.5, 0.01, "no tags = 0.5 default");

// ═══ Season Appropriateness Scoring ══════════════════════════════════

const summerItems: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [], season: "summer" },
  { id: "2", category: "bottoms", color: "blue", tags: [], season: "summer" },
];
assertApprox(scoreSeasonAppropriateness(summerItems, "summer"), 1.0, 0.01, "summer items in summer = 1.0");
assertApprox(scoreSeasonAppropriateness(summerItems, "winter"), 0.0, 0.01, "summer items in winter = 0.0");

const allSeasonItems: ClothingItem[] = [
  { id: "1", category: "tops", color: "white", tags: [], season: "all" },
  { id: "2", category: "bottoms", color: "blue", tags: [] },
];
assertApprox(scoreSeasonAppropriateness(allSeasonItems, "winter"), 1.0, 0.01, "all-season / unset = 1.0");

// ═══ scoreOutfit composite ═══════════════════════════════════════════

const goodOutfit: ClothingItem[] = [
  { id: "1", category: "tops", color: "red", tags: [], style_tags: ["casual"], season: "summer", wear_count: 0 },
  { id: "2", category: "bottoms", color: "black", tags: [], style_tags: ["casual"], season: "summer", wear_count: 0 },
];
const { score: goodScore, breakdown: goodBD } = scoreOutfit(goodOutfit, "summer");
assert(goodScore > 0.5, "good outfit scores above 0.5");
assert(goodBD.color_harmony > 0, "breakdown has color_harmony");
assert(goodBD.season_appropriateness === 1.0, "perfect season match");

// ═══ buildReasonText (Chinese) ═══════════════════════════════════════

const reason1 = buildReasonText({ temp: 22, condition: "Clear" }, "casual", "spring");
assert(reason1.includes("22°C"), "reason includes temperature");
assert(reason1.includes("晴朗"), "reason includes weather condition");
assert(reason1.includes("春季"), "reason includes season");
assert(reason1.includes("休闲"), "reason includes occasion");
assert(reason1.includes("轻薄搭配"), "reason includes outfit style for mild weather");

const reason2 = buildReasonText({ temp: 5, condition: "Snow" }, "formal", "winter");
assert(reason2.includes("5°C"), "cold reason includes temp");
assert(reason2.includes("有雪"), "cold reason includes snow");
assert(reason2.includes("保暖搭配"), "cold weather -> 保暖搭配");

const reasonWithScores = buildReasonText(
  { temp: 22, condition: "Clear" },
  "casual",
  "spring",
  { color_harmony: 0.95, wear_balance: 0.9, style_consistency: 0.85, season_appropriateness: 1.0 }
);
assert(reasonWithScores.includes("配色和谐"), "high color score appends 配色和谐");
assert(reasonWithScores.includes("风格统一"), "high style score appends 风格统一");
assert(reasonWithScores.includes("均衡穿着"), "high wear balance appends 均衡穿着");

// ═══ Multi-outfit generation ═════════════════════════════════════════

const multiItems: ClothingItem[] = [
  { id: "t1", category: "tops", color: "white", tags: ["casual"], style_tags: ["casual"], wear_count: 0 },
  { id: "t2", category: "tops", color: "red", tags: ["casual"], style_tags: ["casual"], wear_count: 5 },
  { id: "b1", category: "bottoms", color: "blue", tags: ["denim"], style_tags: ["casual"], wear_count: 0 },
  { id: "b2", category: "bottoms", color: "black", tags: ["formal"], style_tags: ["formal"], wear_count: 3 },
  { id: "s1", category: "shoes", color: "white", tags: ["casual"], style_tags: ["casual"], wear_count: 1 },
];

const multi = buildMultipleRecommendations(
  multiItems, [], { temp: 22, condition: "Clear" }, "casual", "summer", 3
);
assert(multi.length > 0, "multi returns at least 1 outfit");
assert(multi.length <= 3, "multi respects count limit");
assert(multi.every((r) => r.source === "ai_generated"), "all results are ai_generated");
assert(multi.every((r) => r.item_ids.length >= 2), "all results have at least 2 items");
assert(multi.every((r) => typeof r.score === "number"), "all results have a score");
assert(multi.every((r) => typeof r.reason_text === "string"), "all results have reason_text");

// Verify sorted by score descending
for (let i = 1; i < multi.length; i++) {
  assert(multi[i - 1].score! >= multi[i].score!, `result ${i - 1} score >= result ${i} score`);
}

// Verify no duplicate outfits
const idSets = multi.map((r) => [...r.item_ids].sort().join(","));
assert(new Set(idSets).size === idSets.length, "no duplicate outfits");

// Default count = 3
const defaultCount = buildMultipleRecommendations(
  multiItems, [], { temp: 22, condition: "Clear" }, "casual", "summer"
);
assert(defaultCount.length <= 3, "default count returns up to 3");

// Single count
const singleResult = buildMultipleRecommendations(
  multiItems, [], { temp: 22, condition: "Clear" }, "casual", "summer", 1
);
assert(singleResult.length === 1, "count=1 returns exactly 1");

// Preset fallback with multi
const presetMulti = buildMultipleRecommendations(
  [], presets, { temp: 22, condition: "Clear" }, "casual", undefined, 3
);
assert(presetMulti.length >= 1, "preset fallback returns at least 1");
assert(presetMulti[0].source === "preset", "preset fallback source is preset");
assert(typeof presetMulti[0].reason_text === "string", "preset results have reason_text");

console.log("\nAll tests passed!");
