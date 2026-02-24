import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { buildRecommendation } from "./recommend_logic.ts";

const OPENWEATHER_KEY = Deno.env.get("OPENWEATHER_API_KEY");

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/** 根据温度推断季节 */
function getSeason(temp: number): string {
  if (temp >= 25) return "summer";  // 夏
  if (temp >= 15) return "spring";  // 春/秋
  if (temp >= 5)  return "autumn";  // 深秋
  return "winter";                  // 冬
}

/** 季节中文标签 */
function getSeasonLabel(season: string): string {
  const map: Record<string, string> = {
    summer: "夏季", spring: "春季", autumn: "秋季", winter: "冬季",
  };
  return map[season] ?? season;
}

async function fetchWeather(
  city: string
): Promise<{ temp: number; condition: string; season: string; seasonLabel: string }> {
  const fallback = (temp = 20) => ({
    temp,
    condition: "unknown",
    season: getSeason(temp),
    seasonLabel: getSeasonLabel(getSeason(temp)),
  });

  if (!OPENWEATHER_KEY) return fallback();
  try {
    const url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${OPENWEATHER_KEY}&units=metric`;
    const res = await fetch(url);
    if (!res.ok) return fallback();
    const data = await res.json();
    const temp: number = data.main?.temp ?? 20;
    const condition: string = data.weather?.[0]?.main ?? "unknown";
    const season = getSeason(temp);
    return { temp, condition, season, seasonLabel: getSeasonLabel(season) };
  } catch {
    return fallback();
  }
}

serve(async (req) => {
  // Handle CORS preflight (web-demo / browser clients)
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  const json = (data: unknown, status = 200) =>
    new Response(JSON.stringify(data), {
      status,
      headers: { "Content-Type": "application/json", ...CORS_HEADERS },
    });

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body = await req.json();
    const { user_id, city = "Shanghai", occasion = "casual", season: forceSeason } = body;

    if (!user_id) {
      return json({ error: "user_id required" }, 400);
    }

    const [{ data: items }, { data: presets }, weather] = await Promise.all([
      supabase.from("clothing_items").select("*").eq("user_id", user_id),
      supabase.from("preset_outfits").select("*"),
      fetchWeather(city),
    ]);

    const effectiveSeason: string = forceSeason ?? weather.season;

    const recommendation = buildRecommendation(
      items ?? [],
      presets ?? [],
      weather,
      occasion,
      effectiveSeason
    );

    // Save ai_generated outfit to outfits table
    let outfit_id: string | null = null;
    if (recommendation.source === "ai_generated" && recommendation.item_ids.length > 0) {
      const { data: outfit } = await supabase
        .from("outfits")
        .insert({
          user_id,
          item_ids: recommendation.item_ids,
          occasion,
          season: effectiveSeason,
          source: "ai_generated",
        })
        .select()
        .single();
      outfit_id = outfit?.id ?? null;
    }

    const today = new Date().toISOString().split("T")[0];
    await supabase.from("daily_recommendations").upsert(
      {
        user_id,
        date: today,
        outfit_id,
        weather_data: weather,
        accepted: false,
      },
      { onConflict: "user_id,date" }
    );

    return json({ recommendation, weather, outfit_id });
  } catch (err) {
    return json({ error: String(err) }, 500);
  }
});
