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
  occasion: string
): RecommendationResult {
  const weatherTag = getWeatherTag(weather.temp);

  // Try to build outfit from user's wardrobe
  const tops = items.filter((i) => i.category === "tops");
  const bottoms = items.filter((i) => i.category === "bottoms");
  const shoes = items.filter((i) => i.category === "shoes");

  if (tops.length > 0 && bottoms.length > 0) {
    const chosenTop = tops[Math.floor(Math.random() * tops.length)];
    const chosenBottom = bottoms[Math.floor(Math.random() * bottoms.length)];
    const chosen: string[] = [chosenTop.id, chosenBottom.id];
    if (shoes.length > 0) {
      chosen.push(shoes[Math.floor(Math.random() * shoes.length)].id);
    }
    return { item_ids: chosen, source: "ai_generated" };
  }

  // Fallback to preset
  const matched = presets.filter(
    (p) =>
      p.weather_tags.includes(weatherTag) &&
      (!occasion || p.occasion === occasion)
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
