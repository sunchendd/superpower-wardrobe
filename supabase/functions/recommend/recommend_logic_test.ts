import { buildRecommendation, getWeatherTag } from "./recommend_logic.ts";

function assert(condition: boolean, message: string) {
  if (!condition) throw new Error(`FAIL: ${message}`);
  console.log(`PASS: ${message}`);
}

// Test getWeatherTag
assert(getWeatherTag(30) === "warm", "temp 30 -> warm");
assert(getWeatherTag(22) === "mild", "temp 22 -> mild");
assert(getWeatherTag(15) === "cool", "temp 15 -> cool");
assert(getWeatherTag(5) === "cold", "temp 5 -> cold");

// Test: recommend from wardrobe when items available
const items = [
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
const itemsNoBottoms = [
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

console.log("\nAll tests passed!");
