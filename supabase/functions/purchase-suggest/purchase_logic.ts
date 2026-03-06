// ── Interfaces ──────────────────────────────────────────────────────────

export interface ClothingItem {
  id: string;
  category: string;
  color: string;
  tags: string[];
  season?: string;
  style?: string;
}

export interface UserProfile {
  style_preferences?: string[];
}

export interface Category {
  id: string;
  name: string;
}

export interface PurchaseRecommendation {
  id: string;
  category: string;
  reason: "wardrobe_gap" | "seasonal" | "style_match";
  description: string;
  style_tags: string[];
  season: string;
  priority: number;
}

export interface WardrobeAnalysis {
  total_items: number;
  category_distribution: Record<string, number>;
  color_distribution: Record<string, number>;
  style_distribution: Record<string, number>;
  top_missing: string[];
}

export interface PurchaseSuggestResult {
  recommendations: PurchaseRecommendation[];
  analysis: WardrobeAnalysis;
}

// ── Constants ───────────────────────────────────────────────────────────

/** Ideal wardrobe category ratios (percentage) */
export const IDEAL_RATIOS: Record<string, number> = {
  tops: 35,
  bottoms: 25,
  outerwear: 15,
  shoes: 15,
  accessories: 10,
};

const GAP_THRESHOLD = 0.5; // flag when below 50% of ideal

const SEASON_MAP: Record<string, string> = {
  summer: "夏季",
  winter: "冬季",
  spring: "春季",
  autumn: "秋季",
  all: "四季",
};

const CONTRASTING_COLORS: Record<string, string[]> = {
  black: ["white", "beige", "red"],
  white: ["navy", "black", "burgundy"],
  blue: ["white", "beige", "brown"],
  gray: ["blue", "red", "green"],
  navy: ["white", "beige", "pink"],
  beige: ["navy", "black", "brown"],
};

// ── Helper utilities ────────────────────────────────────────────────────

export function buildDistribution(items: ClothingItem[], key: keyof ClothingItem): Record<string, number> {
  const dist: Record<string, number> = {};
  for (const item of items) {
    const val = String(item[key] ?? "unknown").toLowerCase();
    dist[val] = (dist[val] ?? 0) + 1;
  }
  return dist;
}

export function nextSeason(month: number): string {
  if (month >= 3 && month <= 5) return "summer";
  if (month >= 6 && month <= 8) return "autumn";
  if (month >= 9 && month <= 11) return "winter";
  return "spring"; // Dec-Feb
}

export function nextSeasonLabel(season: string): string {
  return SEASON_MAP[season] ?? season;
}

// ── Analysis engines ────────────────────────────────────────────────────

/** 1. Wardrobe gap analysis — compare category distribution to ideal ratios */
export function analyzeGaps(
  items: ClothingItem[],
  knownCategories: string[],
): PurchaseRecommendation[] {
  const total = items.length || 1;
  const catDist = buildDistribution(items, "category");

  const categories = knownCategories.length > 0
    ? knownCategories
    : Object.keys(IDEAL_RATIOS);

  const recs: PurchaseRecommendation[] = [];

  for (const cat of categories) {
    const idealPct = IDEAL_RATIOS[cat] ?? 0;
    if (idealPct === 0) continue;

    const actual = catDist[cat] ?? 0;
    const actualPct = (actual / total) * 100;
    const ratio = actualPct / idealPct;

    if (ratio < GAP_THRESHOLD) {
      const descMap: Record<string, string> = {
        tops: "你的衣橱中上装偏少，建议补充 T 恤或衬衫",
        bottoms: "你的衣橱中下装偏少，建议补充长裤或牛仔裤",
        outerwear: "你的衣橱中外套偏少，建议补充夹克或风衣",
        shoes: "你的衣橱中鞋子偏少，建议补充休闲鞋或运动鞋",
        accessories: "你的衣橱中配饰偏少，建议补充腰带或围巾",
      };
      recs.push({
        id: crypto.randomUUID(),
        category: cat,
        reason: "wardrobe_gap",
        description: descMap[cat] ?? `你的衣橱中 ${cat} 偏少，建议补充`,
        style_tags: ["casual"],
        season: "all",
        priority: Math.round(10 * (1 - ratio)),
      });
    }
  }

  return recs.sort((a, b) => b.priority - a.priority);
}

/** 2. Seasonal prediction — suggest items for the upcoming season */
export function analyzeSeasonal(
  items: ClothingItem[],
  month: number,
): PurchaseRecommendation[] {
  const upcoming = nextSeason(month);
  const label = nextSeasonLabel(upcoming);

  const seasonalItems = items.filter(
    (i) => i.season === upcoming || i.season === "all",
  );

  const recs: PurchaseRecommendation[] = [];

  if (seasonalItems.length < 3) {
    const seasonSuggestions: Record<string, { cat: string; desc: string }[]> = {
      summer: [
        { cat: "tops", desc: `${label}将至，建议添置短袖或凉爽面料上衣` },
        { cat: "bottoms", desc: `${label}将至，建议添置短裤或轻薄长裤` },
      ],
      winter: [
        { cat: "outerwear", desc: `${label}将至，建议添置羽绒服或厚外套` },
        { cat: "accessories", desc: `${label}将至，建议添置围巾或手套` },
      ],
      spring: [
        { cat: "outerwear", desc: `${label}将至，建议添置薄外套或风衣` },
        { cat: "tops", desc: `${label}将至，建议添置长袖衬衫` },
      ],
      autumn: [
        { cat: "outerwear", desc: `${label}将至，建议添置夹克或卫衣` },
        { cat: "bottoms", desc: `${label}将至，建议添置长裤` },
      ],
    };

    for (const s of seasonSuggestions[upcoming] ?? []) {
      recs.push({
        id: crypto.randomUUID(),
        category: s.cat,
        reason: "seasonal",
        description: s.desc,
        style_tags: [],
        season: upcoming,
        priority: 7,
      });
    }
  }

  return recs;
}

/** 3. Style matching — suggest complementary items based on preferences */
export function analyzeStyle(
  items: ClothingItem[],
  stylePreferences: string[],
): PurchaseRecommendation[] {
  const recs: PurchaseRecommendation[] = [];

  // Style diversity check
  const styleDist = buildDistribution(items, "style");
  const total = items.length || 1;
  const dominantStyle = Object.entries(styleDist).sort((a, b) => b[1] - a[1])[0];

  if (dominantStyle && dominantStyle[1] / total > 0.7) {
    const style = dominantStyle[0];
    if (style === "casual" || stylePreferences.includes("casual")) {
      recs.push({
        id: crypto.randomUUID(),
        category: "tops",
        reason: "style_match",
        description: "你的衣橱以休闲为主，建议补充几件正式单品提升搭配多样性",
        style_tags: ["formal", "smart_casual"],
        season: "all",
        priority: 6,
      });
    } else if (style === "formal" || stylePreferences.includes("formal")) {
      recs.push({
        id: crypto.randomUUID(),
        category: "tops",
        reason: "style_match",
        description: "你的衣橱以正式为主，建议补充休闲单品用于日常搭配",
        style_tags: ["casual", "streetwear"],
        season: "all",
        priority: 6,
      });
    }
  }

  // Color monotone check
  const colorDist = buildDistribution(items, "color");
  const dominantColor = Object.entries(colorDist).sort((a, b) => b[1] - a[1])[0];

  if (dominantColor && dominantColor[1] / total > 0.7) {
    const color = dominantColor[0];
    const suggestions = CONTRASTING_COLORS[color] ?? ["white", "beige"];
    recs.push({
      id: crypto.randomUUID(),
      category: "tops",
      reason: "style_match",
      description: `你的衣橱颜色偏单一（${color}为主），建议尝试 ${suggestions.join("、")} 等对比色`,
      style_tags: stylePreferences.length > 0 ? stylePreferences : ["casual"],
      season: "all",
      priority: 5,
    });
  }

  return recs;
}

// ── Main orchestrator ───────────────────────────────────────────────────

export function generateSuggestions(
  items: ClothingItem[],
  profile: UserProfile,
  categories: Category[],
  month?: number,
): PurchaseSuggestResult {
  const currentMonth = month ?? new Date().getMonth() + 1;
  const stylePrefs = profile.style_preferences ?? [];
  const catNames = categories.map((c) => c.name);

  const gapRecs = analyzeGaps(items, catNames);
  const seasonalRecs = analyzeSeasonal(items, currentMonth);
  const styleRecs = analyzeStyle(items, stylePrefs);

  const all = [...gapRecs, ...seasonalRecs, ...styleRecs];
  // De-duplicate by (category + reason)
  const seen = new Set<string>();
  const unique = all.filter((r) => {
    const key = `${r.category}:${r.reason}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });

  unique.sort((a, b) => b.priority - a.priority);

  const catDist = buildDistribution(items, "category");
  const colorDist = buildDistribution(items, "color");
  const styleDist = buildDistribution(items, "style");

  // Identify top missing categories from gap analysis
  const topMissing = gapRecs.map((r) => r.category);

  return {
    recommendations: unique,
    analysis: {
      total_items: items.length,
      category_distribution: catDist,
      color_distribution: colorDist,
      style_distribution: styleDist,
      top_missing: topMissing,
    },
  };
}
