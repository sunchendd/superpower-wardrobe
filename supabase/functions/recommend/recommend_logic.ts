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
}

export interface PresetOutfit {
  id: string;
  name: string;
  categories: string[];
  occasion: string;
  weather_tags: string[];
}

export interface RecommendationResult {
  item_ids: string[];
  source: "ai_generated" | "preset";
  preset_id?: string;
  preset_name?: string;
}

export function buildRecommendation(
  items: ClothingItem[],
  presets: PresetOutfit[],
  weather: { temp: number; condition: string },
  occasion: string,
  season?: string
): RecommendationResult {
  const weatherTag = getWeatherTag(weather.temp);

  // Try to build outfit from user's wardrobe, prefer seasonally suitable items
  const wardrobePool = season
    ? items.filter((i) => !i.season || i.season === season || i.season === "all")
    : items;

  const tops    = wardrobePool.filter((i) => i.category === "tops");
  const bottoms = wardrobePool.filter((i) => i.category === "bottoms");
  const shoes   = wardrobePool.filter((i) => i.category === "shoes");
  const outers  = wardrobePool.filter((i) => i.category === "outerwear");
  const watches = wardrobePool.filter((i) => i.category === "watch");
  const hats    = wardrobePool.filter((i) => i.category === "hat");

  if (tops.length > 0 && bottoms.length > 0) {
    const pick = <T>(arr: T[]) => arr[Math.floor(Math.random() * arr.length)];
    const chosen: string[] = [pick(tops).id, pick(bottoms).id];
    if (shoes.length > 0)   chosen.push(pick(shoes).id);
    // Cold weather: add outerwear if available
    if (weather.temp < 15 && outers.length > 0) chosen.push(pick(outers).id);
    // Optionally add watch / hat
    if (watches.length > 0 && Math.random() > 0.5) chosen.push(pick(watches).id);
    if (hats.length > 0    && Math.random() > 0.6) chosen.push(pick(hats).id);
    return { item_ids: chosen, source: "ai_generated" };
  }

  // Fallback to preset — match season + weather + occasion
  const matched = presets.filter(
    (p) =>
      p.weather_tags.includes(weatherTag) &&
      (!occasion || p.occasion === occasion) &&
      (!season || !p.season || p.season === season || p.season === "all")
  );
  const pool = matched.length > 0 ? matched : presets;
  const preset = pool.length > 0
    ? pool[Math.floor(Math.random() * pool.length)]
    : null;

  return {
    item_ids: [],
    source: "preset",
    preset_id: preset?.id,
    preset_name: preset?.name,
  };
}
