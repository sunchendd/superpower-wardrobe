import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { buildRecommendation } from "./recommend_logic.ts";

const OPENWEATHER_KEY = Deno.env.get("OPENWEATHER_API_KEY") ?? "";

async function fetchWeather(city: string): Promise<{ temp: number; condition: string }> {
  if (!OPENWEATHER_KEY) {
    return { temp: 20, condition: "unknown" };
  }
  try {
    const url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${OPENWEATHER_KEY}&units=metric`;
    const res = await fetch(url);
    if (!res.ok) return { temp: 20, condition: "unknown" };
    const data = await res.json();
    return {
      temp: data.main?.temp ?? 20,
      condition: data.weather?.[0]?.main ?? "unknown",
    };
  } catch {
    return { temp: 20, condition: "unknown" };
  }
}

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body = await req.json();
    const { user_id, city = "Shanghai", occasion = "casual" } = body;

    if (!user_id) {
      return new Response(JSON.stringify({ error: "user_id required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const [{ data: items }, { data: presets }, weather] = await Promise.all([
      supabase.from("clothing_items").select("*").eq("user_id", user_id),
      supabase.from("preset_outfits").select("*"),
      fetchWeather(city),
    ]);

    const recommendation = buildRecommendation(
      items ?? [],
      presets ?? [],
      weather,
      occasion
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

    return new Response(
      JSON.stringify({ recommendation, weather, outfit_id }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
