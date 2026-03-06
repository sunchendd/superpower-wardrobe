export function getWeatherTag(temp: number): string {
  if (temp >= 28) return "warm";
  if (temp >= 18) return "mild";
  if (temp >= 10) return "cool";
  return "cold";
}

export interface ClothingItem {
  id: string;
  category: string;
  color: string;
  tags: string[];
  season?: string;
  style_tags?: string[];
  wear_count?: number;
  status?: string;
}

export interface PresetOutfit {
  id: string;
  name: string;
  categories: string[];
  occasion: string;
  weather_tags: string[];
  season?: string;
}

export interface ScoredOutfit {
  item_ids: string[];
  items: ClothingItem[];
  score: number;
  breakdown: ScoreBreakdown;
  reason_text: string;
}

export interface ScoreBreakdown {
  color_harmony: number;
  wear_balance: number;
  style_consistency: number;
  season_appropriateness: number;
}

export interface RecommendationResult {
  item_ids: string[];
  source: "ai_generated" | "preset";
  preset_id?: string;
  preset_name?: string;
  score?: number;
  breakdown?: ScoreBreakdown;
  reason_text?: string;
}

// ─── Color harmony helpers ───────────────────────────────────────────

const COLOR_GROUPS: Record<string, string[]> = {
  neutral:  ["white", "black", "gray", "grey", "beige", "cream", "khaki", "brown", "navy"],
  warm:     ["red", "orange", "yellow", "gold", "coral", "pink", "burgundy", "maroon"],
  cool:     ["blue", "green", "purple", "teal", "cyan", "lavender", "mint", "olive"],
};

function getColorGroup(color: string): string {
  const c = color.toLowerCase();
  for (const [group, colors] of Object.entries(COLOR_GROUPS)) {
    if (colors.some((gc) => c.includes(gc))) return group;
  }
  return "neutral";
}

export function scoreColorHarmony(items: ClothingItem[]): number {
  if (items.length < 2) return 1.0;
  const groups = items.map((i) => getColorGroup(i.color));
  const neutralCount = groups.filter((g) => g === "neutral").length;
  const nonNeutral = groups.filter((g) => g !== "neutral");
  const uniqueNonNeutral = new Set(nonNeutral);

  // All neutrals or single accent + neutrals = great harmony
  if (nonNeutral.length === 0) return 0.9;
  if (uniqueNonNeutral.size === 1 && neutralCount > 0) return 1.0;
  if (uniqueNonNeutral.size === 1) return 0.85;
  // Complementary: warm + cool (with neutrals bridging)
  if (uniqueNonNeutral.size === 2 && neutralCount > 0) return 0.8;
  if (uniqueNonNeutral.size === 2) return 0.65;
  return 0.4;
}

// ─── Wear frequency balance ─────────────────────────────────────────

export function scoreWearBalance(items: ClothingItem[]): number {
  const counts = items.map((i) => i.wear_count ?? 0);
  if (counts.length === 0) return 1.0;
  const max = Math.max(...counts);
  if (max === 0) return 1.0;
  // Prefer items with lower wear counts — avg normalized inversely
  const avg = counts.reduce((a, b) => a + b, 0) / counts.length;
  return Math.max(0, 1.0 - avg / (max + 10));
}

// ─── Style consistency ──────────────────────────────────────────────

export function scoreStyleConsistency(items: ClothingItem[]): number {
  const allTags = items.flatMap((i) => i.style_tags ?? i.tags ?? []);
  if (allTags.length === 0) return 0.5;
  const freq: Record<string, number> = {};
  for (const t of allTags) freq[t] = (freq[t] ?? 0) + 1;
  const maxFreq = Math.max(...Object.values(freq));
  // Items sharing tags => higher consistency
  return Math.min(1.0, maxFreq / items.length);
}

// ─── Season appropriateness ─────────────────────────────────────────

export function scoreSeasonAppropriateness(
  items: ClothingItem[],
  season?: string
): number {
  if (!season || items.length === 0) return 0.5;
  let match = 0;
  for (const item of items) {
    if (!item.season || item.season === "all" || item.season === season) match++;
  }
  return match / items.length;
}

// ─── Reason text generation (Chinese) ───────────────────────────────

const CONDITION_CN: Record<string, string> = {
  Clear: "晴朗", Clouds: "多云", Rain: "有雨", Drizzle: "小雨",
  Snow: "有雪", Thunderstorm: "雷雨", Mist: "薄雾", Fog: "有雾",
  Haze: "霾", unknown: "天气未知",
};

const OCCASION_CN: Record<string, string> = {
  casual: "休闲", formal: "正式", business: "商务", sport: "运动",
  date: "约会", party: "派对", outdoor: "户外",
};

const SEASON_CN: Record<string, string> = {
  summer: "夏季", spring: "春季", autumn: "秋季", winter: "冬季",
};

export function buildReasonText(
  weather: { temp: number; condition: string },
  occasion: string,
  season?: string,
  breakdown?: ScoreBreakdown
): string {
  const tempStr = `${Math.round(weather.temp)}°C`;
  const condStr = CONDITION_CN[weather.condition] ?? weather.condition;
  const occStr = OCCASION_CN[occasion] ?? occasion;
  const seasonStr = season ? (SEASON_CN[season] ?? season) : "";

  let reason = `今天气温${tempStr}，${condStr}`;
  if (seasonStr) reason += `，${seasonStr}`;
  reason += `，推荐${occStr}`;

  if (weather.temp >= 28) reason += "清凉搭配";
  else if (weather.temp >= 18) reason += "轻薄搭配";
  else if (weather.temp >= 10) reason += "舒适搭配";
  else reason += "保暖搭配";

  if (breakdown) {
    if (breakdown.color_harmony >= 0.9) reason += "，配色和谐";
    if (breakdown.style_consistency >= 0.8) reason += "，风格统一";
    if (breakdown.wear_balance >= 0.8) reason += "，均衡穿着";
  }

  return reason;
}

// ─── Outfit scoring ─────────────────────────────────────────────────

export function scoreOutfit(
  items: ClothingItem[],
  season?: string
): { score: number; breakdown: ScoreBreakdown } {
  const breakdown: ScoreBreakdown = {
    color_harmony: scoreColorHarmony(items),
    wear_balance: scoreWearBalance(items),
    style_consistency: scoreStyleConsistency(items),
    season_appropriateness: scoreSeasonAppropriateness(items, season),
  };
  const score =
    breakdown.color_harmony * 0.3 +
    breakdown.wear_balance * 0.2 +
    breakdown.style_consistency * 0.3 +
    breakdown.season_appropriateness * 0.2;
  return { score, breakdown };
}

// ─── Multi-outfit generation ────────────────────────────────────────

function allCombinations<T>(buckets: T[][]): T[][] {
  if (buckets.length === 0) return [[]];
  const [first, ...rest] = buckets;
  const restCombos = allCombinations(rest);
  const results: T[][] = [];
  for (const item of first) {
    for (const combo of restCombos) {
      results.push([item, ...combo]);
    }
  }
  return results;
}

export function buildMultipleRecommendations(
  items: ClothingItem[],
  presets: PresetOutfit[],
  weather: { temp: number; condition: string },
  occasion: string,
  season?: string,
  count = 3
): RecommendationResult[] {
  const wardrobePool = season
    ? items.filter((i) => !i.season || i.season === season || i.season === "all")
    : [...items];

  const tops    = wardrobePool.filter((i) => i.category === "tops");
  const bottoms = wardrobePool.filter((i) => i.category === "bottoms");
  const shoes   = wardrobePool.filter((i) => i.category === "shoes");
  const outers  = wardrobePool.filter((i) => i.category === "outerwear");

  if (tops.length > 0 && bottoms.length > 0) {
    // Build required buckets: tops × bottoms (× shoes if available)
    const buckets: ClothingItem[][] = [tops, bottoms];
    if (shoes.length > 0) buckets.push(shoes);

    let combos = allCombinations(buckets);

    // Optionally add outerwear for cold weather
    if (weather.temp < 15 && outers.length > 0) {
      combos = combos.map((combo) => {
        const outer = outers[Math.floor(Math.random() * outers.length)];
        return [...combo, outer];
      });
    }

    // Score every candidate and sort descending
    const scored: ScoredOutfit[] = combos.map((combo) => {
      const { score, breakdown } = scoreOutfit(combo, season);
      return {
        item_ids: combo.map((i) => i.id),
        items: combo,
        score,
        breakdown,
        reason_text: buildReasonText(weather, occasion, season, breakdown),
      };
    });
    scored.sort((a, b) => b.score - a.score);

    // Deduplicate by item_ids set
    const seen = new Set<string>();
    const unique: ScoredOutfit[] = [];
    for (const s of scored) {
      const key = [...s.item_ids].sort().join(",");
      if (!seen.has(key)) {
        seen.add(key);
        unique.push(s);
      }
    }

    return unique.slice(0, count).map((s) => ({
      item_ids: s.item_ids,
      source: "ai_generated" as const,
      score: s.score,
      breakdown: s.breakdown,
      reason_text: s.reason_text,
    }));
  }

  // Fallback to preset
  const weatherTag = getWeatherTag(weather.temp);
  const matched = presets.filter(
    (p) =>
      p.weather_tags.includes(weatherTag) &&
      (!occasion || p.occasion === occasion) &&
      (!season || !p.season || p.season === season || p.season === "all")
  );
  const pool = matched.length > 0 ? matched : presets;
  const selected = pool.slice(0, count);

  if (selected.length === 0) {
    return [{
      item_ids: [],
      source: "preset",
      reason_text: buildReasonText(weather, occasion, season),
    }];
  }

  return selected.map((preset) => ({
    item_ids: [],
    source: "preset" as const,
    preset_id: preset.id,
    preset_name: preset.name,
    reason_text: buildReasonText(weather, occasion, season),
  }));
}

// ─── Legacy single-outfit API (backwards compatible) ────────────────

export function buildRecommendation(
  items: ClothingItem[],
  presets: PresetOutfit[],
  weather: { temp: number; condition: string },
  occasion: string,
  season?: string
): RecommendationResult {
  const results = buildMultipleRecommendations(items, presets, weather, occasion, season, 1);
  return results[0] ?? { item_ids: [], source: "preset" as const };
}
